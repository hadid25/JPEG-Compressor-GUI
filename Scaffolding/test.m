classdef test < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                  matlab.ui.Figure
        compressedImageSizeDisplayValue  matlab.ui.control.Label
        ogImageSizeDisplayValue   matlab.ui.control.Label
        entropyDisplayValue       matlab.ui.control.Label
        CompressedImageSizeLabel  matlab.ui.control.Label
        OriginalImageSizeLabel    matlab.ui.control.Label
        EntropyLabel              matlab.ui.control.Label
        CompressedImageCharacteristicsLabel_2  matlab.ui.control.Label
        SelectacompressionqualityfactorSlider  matlab.ui.control.Slider
        SelectacompressionqualityfactorSliderLabel  matlab.ui.control.Label
        CompressedImageCharacteristicsLabel  matlab.ui.control.Label
        CompressButton            matlab.ui.control.Button
        CompressedImageLabel      matlab.ui.control.Label
        compressedImage           matlab.ui.control.Image
        OriginalImageLabel        matlab.ui.control.Label
        ogImage                   matlab.ui.control.Image
        Image                     matlab.ui.control.Image
        ChooseImageButton         matlab.ui.control.Button
        JPEGCOMPRESSORLabel       matlab.ui.control.Label
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: ChooseImageButton
        function ChooseImageButtonPushed(app, event)
            [file, path] = uigetfile('*.jpg');
            global fullpath;
            fullpath = strcat(path,file);
            global I;
            I = imread(fullpath);
            app.ogImage.ImageSource = fullpath;
        end

        % Button pushed function: CompressButton
        function CompressButtonPushed(app, event)
            global I;
            I1= I;
            [row coln]= size(I);
            I= double(I);
            %---------------------------------------------------------
            % Subtracting each image pixel value by 128 
            %--------------------------------------------------------
            I = I - (128*ones(256));

            quality = app.SelectacompressionqualityfactorSlider.Value;

            
            %----------------------------------------------------------
            % Quality Matrix Formulation
            %----------------------------------------------------------
            Q50 = [ 16 11 10 16 24 40 51 61;
                 12 12 14 19 26 58 60 55;
                 14 13 16 24 40 57 69 56;
                 14 17 22 29 51 87 80 62; 
                 18 22 37 56 68 109 103 77;
                 24 35 55 64 81 104 113 92;
                 49 64 78 87 103 121 120 101;
                 72 92 95 98 112 100 103 99];
             


             if quality > 50
                 QX = round(Q50.*(ones(8)*((100-quality)/50)));
                 QX = uint8(QX);
            elseif quality < 50
                 QX = round(Q50.*(ones(8)*(50/quality)));
                 QX = uint8(QX);
            elseif quality == 50
                 QX = Q50;
             end

        
        
        %----------------------------------------------------------
        % Formulation of forward DCT Matrix and inverse DCT matrix
        %----------------------------------------------
        DCT_matrix8 = dct(eye(8));
        iDCT_matrix8 = DCT_matrix8';   %inv(DCT_matrix8);
        
        
        
        
        %----------------------------------------------------------
        % Jpeg Compression
        %----------------------------------------------------------
        dct_restored = zeros(row,coln);
        QX = double(QX);
        %----------------------------------------------------------
        % Jpeg Encoding
        %----------------------------------------------------------
        %----------------------------------------------------------
        % Forward Discret Cosine Transform
        %----------------------------------------------------------
        
        for i1=[1:8:row]
            for i2=[1:8:coln]
                zBLOCK=I(i1:i1+7,i2:i2+7);
                win1=DCT_matrix8*zBLOCK*iDCT_matrix8;
                dct_domain(i1:i1+7,i2:i2+7)=win1;
            end
        end
        %-----------------------------------------------------------
        % Quantization of the DCT coefficients
        %-----------------------------------------------------------
        for i1=[1:8:row]
            for i2=[1:8:coln]
                win1 = dct_domain(i1:i1+7,i2:i2+7);
                win2=round(win1./QX);
                dct_quantized(i1:i1+7,i2:i2+7)=win2;
            end
        end
        
        
        
        
        %-----------------------------------------------------------
        % Jpeg Decoding 
        %-----------------------------------------------------------
        % Dequantization of DCT Coefficients
        %-----------------------------------------------------------
        for i1=[1:8:row]
            for i2=[1:8:coln]
                win2 = dct_quantized(i1:i1+7,i2:i2+7);
                win3 = win2.*QX;
                dct_dequantized(i1:i1+7,i2:i2+7) = win3;
            end
        end
        %-----------------------------------------------------------
        % Inverse DISCRETE COSINE TRANSFORM
        %-----------------------------------------------------------
        for i1=[1:8:row]
            for i2=[1:8:coln]
                win3 = dct_dequantized(i1:i1+7,i2:i2+7);
                win4=iDCT_matrix8*win3*DCT_matrix8;
                dct_restored(i1:i1+7,i2:i2+7)=win4;
            end
        end
        I2=dct_restored;
        Icompressed = I2(:,1:256);
        
        
        % ---------------------------------------------------------
        % Conversion of Image Matrix to Intensity image
        %----------------------------------------------------------
        
        K=mat2gray(I2);
        Kcompressed = mat2gray(Icompressed);

        delete('compressed.jpg') %delete old compressed image if any
        imwrite(Kcompressed,'compressed.jpg');
       



        
        %----------------------------------------------------------
        %Display of Results
        %----------------------------------------------------------
        app.compressedImage.ImageSource = 'compressed.jpg'; %%%%% The refreshing after the first compression is not happening

        precision = 3; %number of digits
        %Displaying Entropy Value
        e = entropy(K);
        app.entropyDisplayValue.Text = num2str(e,precision);
        app.entropyDisplayValue.FontColor = 'k';

        %Displaying Original Image Size Value
        global fullpath; %globalizing fullpath so it can be used in this function
        ogsize = pyrunfile('file_size.py','size', file_name = fullpath); %reading the size of the original file
        app.ogImageSizeDisplayValue.Text = num2str(ogsize,precision);
        app.ogImageSizeDisplayValue.FontColor = 'k';


        %Displaying Compressed Image Size Value
        compsize = pyrunfile('file_size.py', 'size', file_name = 'compressed.jpg'); %reading the size of the compressed file
        app.compressedImageSizeDisplayValue.Text = num2str(compsize,precision);
        app.compressedImageSizeDisplayValue.FontColor = 'k';
        end

        % Value changed function: SelectacompressionqualityfactorSlider
        function SelectacompressionqualityfactorSliderValueChanged(app, event)
            value = app.SelectacompressionqualityfactorSlider.Value;
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [1 1 1];
            app.UIFigure.Position = [100 100 783 804];
            app.UIFigure.Name = 'MATLAB App';

            % Create JPEGCOMPRESSORLabel
            app.JPEGCOMPRESSORLabel = uilabel(app.UIFigure);
            app.JPEGCOMPRESSORLabel.FontName = 'Berlin Sans FB';
            app.JPEGCOMPRESSORLabel.FontSize = 36;
            app.JPEGCOMPRESSORLabel.Position = [244 622 314 48];
            app.JPEGCOMPRESSORLabel.Text = 'JPEG COMPRESSOR';

            % Create ChooseImageButton
            app.ChooseImageButton = uibutton(app.UIFigure, 'push');
            app.ChooseImageButton.ButtonPushedFcn = createCallbackFcn(app, @ChooseImageButtonPushed, true);
            app.ChooseImageButton.FontSize = 18;
            app.ChooseImageButton.Position = [343 580 132 30];
            app.ChooseImageButton.Text = 'Choose Image';

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.Position = [108 669 605 128];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'Images', 'ipr2.v15.3.cover.jpg');

            % Create ogImage
            app.ogImage = uiimage(app.UIFigure);
            app.ogImage.Position = [89 338 237 201];

            % Create OriginalImageLabel
            app.OriginalImageLabel = uilabel(app.UIFigure);
            app.OriginalImageLabel.FontSize = 18;
            app.OriginalImageLabel.Position = [146 538 122 23];
            app.OriginalImageLabel.Text = 'Original Image';

            % Create compressedImage
            app.compressedImage = uiimage(app.UIFigure);
            app.compressedImage.Position = [497 328 237 201];

            % Create CompressedImageLabel
            app.CompressedImageLabel = uilabel(app.UIFigure);
            app.CompressedImageLabel.FontSize = 18;
            app.CompressedImageLabel.Position = [543 538 162 23];
            app.CompressedImageLabel.Text = 'Compressed Image';

            % Create CompressButton
            app.CompressButton = uibutton(app.UIFigure, 'push');
            app.CompressButton.ButtonPushedFcn = createCallbackFcn(app, @CompressButtonPushed, true);
            app.CompressButton.FontSize = 18;
            app.CompressButton.Position = [352 218 100 30];
            app.CompressButton.Text = 'Compress';

            % Create CompressedImageCharacteristicsLabel
            app.CompressedImageCharacteristicsLabel = uilabel(app.UIFigure);
            app.CompressedImageCharacteristicsLabel.FontSize = 14;
            app.CompressedImageCharacteristicsLabel.FontAngle = 'italic';
            app.CompressedImageCharacteristicsLabel.FontColor = [1 1 1];
            app.CompressedImageCharacteristicsLabel.Position = [286 247 226 22];
            app.CompressedImageCharacteristicsLabel.Text = 'Compressed Image Characteristics';

            % Create SelectacompressionqualityfactorSliderLabel
            app.SelectacompressionqualityfactorSliderLabel = uilabel(app.UIFigure);
            app.SelectacompressionqualityfactorSliderLabel.HorizontalAlignment = 'right';
            app.SelectacompressionqualityfactorSliderLabel.Position = [122 289 192 22];
            app.SelectacompressionqualityfactorSliderLabel.Text = 'Select a compression quality factor';

            % Create SelectacompressionqualityfactorSlider
            app.SelectacompressionqualityfactorSlider = uislider(app.UIFigure);
            app.SelectacompressionqualityfactorSlider.ValueChangedFcn = createCallbackFcn(app, @SelectacompressionqualityfactorSliderValueChanged, true);
            app.SelectacompressionqualityfactorSlider.Position = [335 298 150 3];

            % Create CompressedImageCharacteristicsLabel_2
            app.CompressedImageCharacteristicsLabel_2 = uilabel(app.UIFigure);
            app.CompressedImageCharacteristicsLabel_2.FontSize = 18;
            app.CompressedImageCharacteristicsLabel_2.FontWeight = 'bold';
            app.CompressedImageCharacteristicsLabel_2.FontAngle = 'italic';
            app.CompressedImageCharacteristicsLabel_2.Position = [258 175 310 23];
            app.CompressedImageCharacteristicsLabel_2.Text = 'Compressed Image Characteristics';

            % Create EntropyLabel
            app.EntropyLabel = uilabel(app.UIFigure);
            app.EntropyLabel.FontSize = 18;
            app.EntropyLabel.Position = [27 153 77 23];
            app.EntropyLabel.Text = 'Entropy: ';

            % Create OriginalImageSizeLabel
            app.OriginalImageSizeLabel = uilabel(app.UIFigure);
            app.OriginalImageSizeLabel.FontSize = 18;
            app.OriginalImageSizeLabel.Position = [28 120 167 23];
            app.OriginalImageSizeLabel.Text = 'Original Image Size:';

            % Create CompressedImageSizeLabel
            app.CompressedImageSizeLabel = uilabel(app.UIFigure);
            app.CompressedImageSizeLabel.FontSize = 18;
            app.CompressedImageSizeLabel.Position = [30 88 208 23];
            app.CompressedImageSizeLabel.Text = 'Compressed Image Size:';

            % Create entropyDisplayValue
            app.entropyDisplayValue = uilabel(app.UIFigure);
            app.entropyDisplayValue.FontSize = 18;
            app.entropyDisplayValue.FontColor = [1 1 1];
            app.entropyDisplayValue.Position = [110 153 49 23];

            % Create ogImageSizeDisplayValue
            app.ogImageSizeDisplayValue = uilabel(app.UIFigure);
            app.ogImageSizeDisplayValue.FontSize = 18;
            app.ogImageSizeDisplayValue.FontColor = [1 1 1];
            app.ogImageSizeDisplayValue.Position = [220 120 49 23];

            % Create compressedImageSizeDisplayValue
            app.compressedImageSizeDisplayValue = uilabel(app.UIFigure);
            app.compressedImageSizeDisplayValue.FontSize = 18;
            app.compressedImageSizeDisplayValue.FontColor = [1 1 1];
            app.compressedImageSizeDisplayValue.Position = [245 88 49 23];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = test

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end