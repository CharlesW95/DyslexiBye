use_frameworks!

target 'DyslexiBye' do
    pod 'TesseractOCRiOS', '4.0.0'
    pod 'GPUImage2'

    post_install do |installer|
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
      end
    end

end

