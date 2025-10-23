// ReactNativeTextRecognitionModule.kt

package com.reactnativetextrecognition

import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import com.facebook.react.bridge.*
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.TextRecognizer
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File
import java.io.FileOutputStream
import kotlin.math.min

class ReactNativeTextRecognitionModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String {
        return "ReactNativeTextRecognition"
    }

    @ReactMethod
    fun recognizeText(fileUrl: String, options: ReadableMap, callback: Callback) {
        try {
            val uri = Uri.parse(fileUrl)
            val context = reactApplicationContext

            // Parse options
            val languages = if (options.hasKey("languages")) {
                options.getArray("languages")?.toArrayList()?.map { it.toString() } ?: emptyList()
            } else {
                emptyList()
            }
            
            val maxPages = if (options.hasKey("maxPages")) {
                options.getInt("maxPages")
            } else {
                Integer.MAX_VALUE
            }
            
            val pdfDpi = if (options.hasKey("pdfDpi")) {
                options.getInt("pdfDpi")
            } else {
                400  // High quality by default (increased from 300)
            }

            // Smart defaults: detect file type for optimized settings
            val path = uri.path ?: ""
            val isPdf = path.lowercase().endsWith(".pdf")
            
            // Apply PDF-optimized defaults when not explicitly specified
            val recognitionLevel = if (options.hasKey("recognitionLevel")) {
                options.getString("recognitionLevel") ?: "word"
            } else {
                // PDFs work better with 'line' recognition (handles scanned docs better)
                // Images work better with 'word' recognition (more precise)
                if (isPdf) "line" else "word"
            }
            
            Log.d(NAME, "Recognition mode: $path (PDF: $isPdf, level: $recognitionLevel)")

            if (isPdf) {
                processPdfFile(uri, languages, recognitionLevel, maxPages, pdfDpi, callback)
            } else {
                processImageFile(uri, languages, recognitionLevel, callback)
            }
        } catch (e: Exception) {
            sendError(callback, "Failed to process file: ${e.message}")
        }
    }

    @ReactMethod
    fun detectText(imgUrl: String, callback: Callback) {
        try {
            val uri = Uri.parse(imgUrl)
            val image = InputImage.fromFilePath(reactApplicationContext, uri)
            
            // Use Latin recognizer for legacy method
            val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            
            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    val words = Arguments.createArray()
                    for (block in visionText.textBlocks) {
                        for (line in block.lines) {
                            for (element in line.elements) {
                                val word = Arguments.createMap()
                                word.putString("text", element.text)
                                word.putString("confidence", "1.0") // ML Kit doesn't provide confidence
                                words.pushMap(word)
                            }
                        }
                    }
                    
                    val result = Arguments.createMap()
                    result.putArray("detectedWords", words)
                    callback.invoke(result)
                }
                .addOnFailureListener { e ->
                    val result = Arguments.createMap()
                    result.putBoolean("error", true)
                    result.putString("errorMessage", e.message)
                    callback.invoke(result)
                }
        } catch (e: Exception) {
            val result = Arguments.createMap()
            result.putBoolean("error", true)
            result.putString("errorMessage", e.message)
            callback.invoke(result)
        }
    }

    @ReactMethod
    fun isAvailable(promise: Promise) {
        // ML Kit is available on all supported Android versions
        promise.resolve(true)
    }

    @ReactMethod
    fun getSupportedLanguages(promise: Promise) {
        val languages = Arguments.createArray()
        // ML Kit supported languages
        languages.pushString("en") // Latin
        languages.pushString("zh") // Chinese
        languages.pushString("ja") // Japanese
        languages.pushString("ko") // Korean
        languages.pushString("hi") // Devanagari
        languages.pushString("ar") // Arabic
        languages.pushString("th") // Thai
        languages.pushString("vi") // Vietnamese
        promise.resolve(languages)
    }

    private fun processImageFile(
        uri: Uri,
        languages: List<String>,
        recognitionLevel: String,
        callback: Callback
    ) {
        try {
            val image = InputImage.fromFilePath(reactApplicationContext, uri)
            val recognizer = getRecognizer(languages)
            
            recognizer.process(image)
                .addOnSuccessListener { visionText ->
                    val result = formatRecognitionResult(
                        visionText,
                        0,
                        image.width,
                        image.height,
                        recognitionLevel
                    )
                    
                    val pages = Arguments.createArray()
                    pages.pushMap(result)
                    
                    val response = Arguments.createMap()
                    response.putBoolean("success", true)
                    response.putArray("pages", pages)
                    response.putInt("totalPages", 1)
                    response.putString("fullText", visionText.text)
                    
                    callback.invoke(response)
                }
                .addOnFailureListener { e ->
                    sendError(callback, "Text recognition failed: ${e.message}")
                }
        } catch (e: Exception) {
            sendError(callback, "Failed to process image: ${e.message}")
        }
    }

    private fun processPdfFile(
        uri: Uri,
        languages: List<String>,
        recognitionLevel: String,
        maxPages: Int,
        pdfDpi: Int,
        callback: Callback
    ) {
        try {
            val context = reactApplicationContext
            val inputStream = context.contentResolver.openInputStream(uri)
            
            if (inputStream == null) {
                sendError(callback, "Cannot open PDF file")
                return
            }
            
            // Copy PDF to temporary file (PdfRenderer requires a file)
            val tempFile = File.createTempFile("temp_pdf", ".pdf", context.cacheDir)
            FileOutputStream(tempFile).use { output ->
                inputStream.copyTo(output)
            }
            inputStream.close()
            
            val parcelFileDescriptor = ParcelFileDescriptor.open(
                tempFile,
                ParcelFileDescriptor.MODE_READ_ONLY
            )
            
            val pdfRenderer = PdfRenderer(parcelFileDescriptor)
            val pageCount = pdfRenderer.pageCount
            val pagesToProcess = min(pageCount, maxPages)
            
            val allPages = Arguments.createArray()
            val fullTextBuilder = StringBuilder()
            
            for (i in 0 until pagesToProcess) {
                val page = pdfRenderer.openPage(i)
                
                // Calculate dimensions based on DPI (default 400 for high quality)
                val scale = pdfDpi / 72f
                val width = (page.width * scale).toInt()
                val height = (page.height * scale).toInt()
                
                // Render page to high-quality bitmap
                val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                // Use RENDER_MODE_FOR_PRINT for highest quality
                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_PRINT)
                page.close()
                
                // Recognize text in bitmap
                val image = InputImage.fromBitmap(bitmap, 0)
                val recognizer = getRecognizer(languages)
                
                // Process synchronously (blocking)
                val task = recognizer.process(image)
                while (!task.isComplete) {
                    Thread.sleep(100)
                }
                
                if (task.isSuccessful) {
                    val visionText = task.result
                    val pageResult = formatRecognitionResult(
                        visionText,
                        i,
                        width,
                        height,
                        recognitionLevel
                    )
                    allPages.pushMap(pageResult)
                    
                    fullTextBuilder.append(visionText.text)
                    fullTextBuilder.append("\n\n")
                }
                
                bitmap.recycle()
            }
            
            pdfRenderer.close()
            parcelFileDescriptor.close()
            tempFile.delete()
            
            val response = Arguments.createMap()
            response.putBoolean("success", true)
            response.putArray("pages", allPages)
            response.putInt("totalPages", pageCount)
            response.putString("fullText", fullTextBuilder.toString().trim())
            
            callback.invoke(response)
            
        } catch (e: Exception) {
            sendError(callback, "Failed to process PDF: ${e.message}")
        }
    }

    private fun getRecognizer(languages: List<String>): TextRecognizer {
        // Determine the best recognizer based on primary language
        val primaryLang = languages.firstOrNull()?.lowercase() ?: "en"
        
        return when {
            primaryLang.startsWith("zh") || primaryLang.startsWith("cn") -> {
                TextRecognition.getClient(ChineseTextRecognizerOptions.Builder().build())
            }
            primaryLang.startsWith("ja") -> {
                TextRecognition.getClient(JapaneseTextRecognizerOptions.Builder().build())
            }
            primaryLang.startsWith("ko") -> {
                TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build())
            }
            primaryLang.startsWith("hi") || primaryLang.startsWith("sa") || primaryLang.startsWith("mr") || primaryLang.startsWith("ne") -> {
                TextRecognition.getClient(DevanagariTextRecognizerOptions.Builder().build())
            }
            else -> {
                // Default to Latin script (covers English, Spanish, French, German, etc.)
                TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            }
        }
    }

    private fun formatRecognitionResult(
        visionText: Text,
        pageNumber: Int,
        width: Int,
        height: Int,
        recognitionLevel: String
    ): WritableMap {
        val elements = Arguments.createArray()
        
        when (recognitionLevel) {
            "block" -> {
                for (block in visionText.textBlocks) {
                    val element = createTextElement(block.text, block.boundingBox, width, height, "block")
                    elements.pushMap(element)
                }
            }
            "line" -> {
                for (block in visionText.textBlocks) {
                    for (line in block.lines) {
                        val element = createTextElement(line.text, line.boundingBox, width, height, "line")
                        elements.pushMap(element)
                    }
                }
            }
            else -> { // "word"
                for (block in visionText.textBlocks) {
                    for (line in block.lines) {
                        for (word in line.elements) {
                            val element = createTextElement(word.text, word.boundingBox, width, height, "word")
                            elements.pushMap(element)
                        }
                    }
                }
            }
        }
        
        val dimensions = Arguments.createMap()
        dimensions.putInt("width", width)
        dimensions.putInt("height", height)
        
        val page = Arguments.createMap()
        page.putInt("pageNumber", pageNumber)
        page.putMap("dimensions", dimensions)
        page.putArray("elements", elements)
        page.putString("fullText", visionText.text)
        
        return page
    }

    private fun createTextElement(
        text: String,
        boundingBox: android.graphics.Rect?,
        imageWidth: Int,
        imageHeight: Int,
        level: String
    ): WritableMap {
        val element = Arguments.createMap()
        element.putString("text", text)
        element.putDouble("confidence", 1.0) // ML Kit doesn't provide confidence scores
        element.putString("level", level)
        
        if (boundingBox != null) {
            val box = Arguments.createMap()
            
            // Normalized coordinates (0-1)
            box.putDouble("x", boundingBox.left.toDouble() / imageWidth)
            box.putDouble("y", boundingBox.top.toDouble() / imageHeight)
            box.putDouble("width", boundingBox.width().toDouble() / imageWidth)
            box.putDouble("height", boundingBox.height().toDouble() / imageHeight)
            
            // Absolute coordinates
            val absoluteBox = Arguments.createMap()
            absoluteBox.putInt("x", boundingBox.left)
            absoluteBox.putInt("y", boundingBox.top)
            absoluteBox.putInt("width", boundingBox.width())
            absoluteBox.putInt("height", boundingBox.height())
            box.putMap("absoluteBox", absoluteBox)
            
            element.putMap("boundingBox", box)
        }
        
        return element
    }

    private fun sendError(callback: Callback, message: String) {
        val result = Arguments.createMap()
        result.putBoolean("success", false)
        result.putBoolean("error", true)
        result.putString("errorMessage", message)
        callback.invoke(result)
    }
}

