# react-native-text-recognition.podspec

require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

folly_compiler_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32'

Pod::Spec.new do |s|
  s.name         = "react-native-text-recognition"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                  React Native Text Recognition - Advanced OCR with Vision API
                  Supports iOS 13+ (iOS 16+ recommended for VNRecognizeTextRequestRevision3), PDF support, and multi-language recognition.
                  Automatically uses the best available API for each iOS version.
                   DESC
  s.homepage     = "https://github.com/dariyd/react-native-text-recognition"
  s.license      = "MIT"
  s.authors      = { "dariyd" => "dariyd@users.noreply.github.com" }
  s.platforms    = { :ios => "13.0" }
  s.source       = { :git => "https://github.com/dariyd/react-native-text-recognition.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm}"
  s.requires_arc = true

  # Use install_modules_dependencies helper for better compatibility
  if respond_to?(:install_modules_dependencies, true)
    install_modules_dependencies(s)
  else
    s.dependency "React-Core"
    
    # Additional dependencies for new architecture
    if ENV['RCT_NEW_ARCH_ENABLED'] == '1'
      s.compiler_flags = folly_compiler_flags + " -DRCT_NEW_ARCH_ENABLED=1"
      s.pod_target_xcconfig    = {
        "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost\"",
        "OTHER_CPLUSPLUSFLAGS" => "-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1",
        "CLANG_CXX_LANGUAGE_STANDARD" => "c++17"
      }
      s.dependency "React-Codegen"
      s.dependency "RCT-Folly"
      s.dependency "RCTRequired"
      s.dependency "RCTTypeSafety"
      s.dependency "ReactCommon/turbomodule/core"
    end
  end

  # System frameworks
  s.frameworks = "Vision", "VisionKit", "PDFKit", "CoreImage"
end

