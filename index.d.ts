// Type definitions for react-native-text-recognition

export interface TextRecognitionOptions {
  /**
   * Recognition language hints (e.g., ['en', 'es', 'fr'])
   * 
   * - Empty array [] or omitted: Automatic language detection (iOS 16+ recommended)
   * - Specific languages: Use as hints for better accuracy
   * 
   * iOS 16+: Supports 100+ languages with automatic detection
   * iOS 13-15: Limited to ~20 languages, works best with Latin scripts
   * Android: Defaults to Latin script if not specified
   * 
   * Default: [] (automatic detection)
   */
  languages?: string[];
  
  /**
   * Recognition level: 'word' | 'line' | 'block'
   * Default: 'word'
   */
  recognitionLevel?: 'word' | 'line' | 'block';
  
  /**
   * Use fast recognition (lower accuracy, faster speed)
   * Default: false
   */
  useFastRecognition?: boolean;
  
  /**
   * For PDFs: Maximum number of pages to process
   * Default: all pages
   */
  maxPages?: number;
  
  /**
   * For PDFs: DPI for converting PDF to images
   * Default: 300
   */
  pdfDpi?: number;
}

export interface TextBoundingBox {
  /**
   * Top-left X coordinate (normalized 0-1)
   */
  x: number;
  
  /**
   * Top-left Y coordinate (normalized 0-1)
   */
  y: number;
  
  /**
   * Width (normalized 0-1)
   */
  width: number;
  
  /**
   * Height (normalized 0-1)
   */
  height: number;
  
  /**
   * Absolute coordinates in pixels (optional)
   */
  absoluteBox?: {
    x: number;
    y: number;
    width: number;
    height: number;
  };
}

export interface RecognizedTextElement {
  /**
   * Recognized text content
   */
  text: string;
  
  /**
   * Confidence score (0-1)
   */
  confidence: number;
  
  /**
   * Bounding box coordinates
   */
  boundingBox: TextBoundingBox;
  
  /**
   * Detected language (if available)
   */
  language?: string;
  
  /**
   * Element level: 'word' | 'line' | 'block'
   */
  level: 'word' | 'line' | 'block';
}

export interface RecognizedPage {
  /**
   * Page number (starting from 0)
   */
  pageNumber: number;
  
  /**
   * Page dimensions
   */
  dimensions: {
    width: number;
    height: number;
  };
  
  /**
   * All recognized text elements in this page
   */
  elements: RecognizedTextElement[];
  
  /**
   * Full text content of the page (concatenated)
   */
  fullText: string;
}

export interface TextRecognitionResult {
  /**
   * Success flag
   */
  success: boolean;
  
  /**
   * Error flag
   */
  error?: boolean;
  
  /**
   * Error message (if error occurred)
   */
  errorMessage?: string;
  
  /**
   * Array of recognized pages
   */
  pages?: RecognizedPage[];
  
  /**
   * Total number of pages processed
   */
  totalPages?: number;
  
  /**
   * Full text from all pages (concatenated)
   */
  fullText?: string;
}

/**
 * Recognizes text from an image or PDF file
 * @param fileUrl - Local file URL (file://, content://, or http(s)://)
 * @param options - Recognition options
 * @param callback - Optional callback for compatibility
 * @returns Promise with recognition results
 */
export function recognizeText(
  fileUrl: string,
  options?: TextRecognitionOptions,
  callback?: (result: TextRecognitionResult) => void
): Promise<TextRecognitionResult>;

/**
 * Legacy method name for backward compatibility
 * @deprecated Use recognizeText instead
 */
export function detectText(
  fileUrl: string,
  callback?: (result: any) => void
): Promise<any>;

/**
 * Check if text recognition is available on this device
 * @returns Promise<boolean>
 */
export function isAvailable(): Promise<boolean>;

/**
 * Get list of supported languages for text recognition
 * @returns Promise<string[]>
 */
export function getSupportedLanguages(): Promise<string[]>;

declare const ReactNativeTextRecognition: {
  recognizeText: typeof recognizeText;
  detectText: typeof detectText;
  isAvailable: typeof isAvailable;
  getSupportedLanguages: typeof getSupportedLanguages;
};

export default ReactNativeTextRecognition;

