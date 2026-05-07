function [autoenc_net, features] = train_deep_autoencoder(audio_data)
    % audio_data: ماتریس داده‌های صوتی ورودی
    
    % تعریف ساختار شبکه عمیق (لایه ورودی، لایه‌های مخفی متعدد، لایه خروجی)
    hiddenLayerSize1 = 128;
    hiddenLayerSize2 = 64;  % لایه گلوگاه (Bottleneck) برای استخراج ویژگی
    
    % ایجاد شبکه عصبی پیش‌خور به عنوان خودرمزنگار
    net = feedforwardnet([hiddenLayerSize1, hiddenLayerSize2, hiddenLayerSize1], 'trainlm');
    
    % تنظیمات تقسیم داده‌ها
    net.divideParam.trainRatio = 70/100;
    net.divideParam.valRatio = 15/100;
    net.divideParam.testRatio = 15/100;
    
    % تنظیمات توقف زودهنگام و آموزش
    net.trainParam.epochs = 1000;
    net.trainParam.goal = 1e-5;
    
    % آموزش شبکه (ورودی و خروجی هدف یکسان هستند)
    disp('در حال آموزش شبکه عصبی خودرمزنگار عمیق...');
    [autoenc_net, ~] = train(net, audio_data, audio_data);
    
    % استخراج ویژگی‌ها از لایه میانی (در صورت نیاز برای تحلیل)
    % در اینجا برای سادگی، خروجی بازسازی شده را مد نظر قرار می‌دهیم
    features = autoenc_net(audio_data);
end
