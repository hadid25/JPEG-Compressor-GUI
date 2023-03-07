classdef JPEGCompressor_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        Unit2                       matlab.ui.control.Label
        Unit1                       matlab.ui.control.Label
        Label2                      matlab.ui.control.Label
        GROUP4Label                 matlab.ui.control.Label
        MsEvelynAmuLabel            matlab.ui.control.Label
        DrAliSeguMohamedHyderLabel  matlab.ui.control.Label
        SpecialthankstoLabel        matlab.ui.control.Label
        EE421DIGITALANDANALOGSIGNALPROCESSINGINTELECOMMUNICATIONSLabel  matlab.ui.control.Label
        compressedImageSizeDisplayValue  matlab.ui.control.Label
        ogImageSizeDisplayValue     matlab.ui.control.Label
        entropyDisplayValue         matlab.ui.control.Label
        CompressedImageSizeLabel    matlab.ui.control.Label
        OriginalImageSizeLabel      matlab.ui.control.Label
        EntropyLabel                matlab.ui.control.Label
        CompressedImageCharacteristicsLabel_2  matlab.ui.control.Label
        SelectacompressionqualityfactorSlider  matlab.ui.control.Slider
        SelectacompressionqualityfactorSliderLabel  matlab.ui.control.Label
        CompressButton              matlab.ui.control.Button
        CompressedImageLabel        matlab.ui.control.Label
        compressedImage             matlab.ui.control.Image
        OriginalImageLabel          matlab.ui.control.Label
        ogImage                     matlab.ui.control.Image
        Image                       matlab.ui.control.Image
        ChooseImageButton           matlab.ui.control.Button
        JPEGCOMPRESSORLabel         matlab.ui.control.Label
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

    %Delete compressed image to show refresh
        delete('compressed.jpg');
        app.compressedImage.delete()
        drawnow();


       






        
        %----------------------------------------------------------
        %Display of Results
        %----------------------------------------------------------
        imwrite(Kcompressed,'compressed.jpg');
        app.compressedImage = uiimage(app.UIFigure);
        app.compressedImage.Position = [497 328 237 201];
        app.compressedImage.ImageSource = repmat(Kcompressed, 1, 1, 3); %%%%% The refreshing after the first compression is not happening
        drawnow();

        precision = 3; %number of digits
        %Displaying Entropy Value
        e = entropy(K);
        app.entropyDisplayValue.Text = num2str(e,precision);
        app.entropyDisplayValue.FontColor = 'w';

       
        %Displaying Original Image Size Value
        global fullpath; %globalizing fullpath so it can be used in this function
        ogsize = pyrunfile('file_size.py','size', file_name = fullpath); %reading the size of the original file
        app.ogImageSizeDisplayValue.Text = num2str(ogsize,precision);
        app.ogImageSizeDisplayValue.FontColor = 'w';


        %Displaying Compressed Image Size Value
        compsize = pyrunfile('file_size.py', 'size', file_name = 'compressed.jpg'); %reading the size of the compressed file
        app.compressedImageSizeDisplayValue.Text = num2str(compsize,precision);
        app.compressedImageSizeDisplayValue.FontColor = 'w';
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
            app.UIFigure.Color = [0.6863 0.2275 0.2588];
            app.UIFigure.Position = [100 100 783 804];
            app.UIFigure.Name = 'MATLAB App';

            % Create JPEGCOMPRESSORLabel
            app.JPEGCOMPRESSORLabel = uilabel(app.UIFigure);
            app.JPEGCOMPRESSORLabel.FontName = 'Berlin Sans FB';
            app.JPEGCOMPRESSORLabel.FontSize = 36;
            app.JPEGCOMPRESSORLabel.FontColor = [1 1 1];
            app.JPEGCOMPRESSORLabel.Position = [244 622 314 48];
            app.JPEGCOMPRESSORLabel.Text = 'JPEG COMPRESSOR';

            % Create ChooseImageButton
            app.ChooseImageButton = uibutton(app.UIFigure, 'push');
            app.ChooseImageButton.ButtonPushedFcn = createCallbackFcn(app, @ChooseImageButtonPushed, true);
            app.ChooseImageButton.FontName = 'Berlin Sans FB';
            app.ChooseImageButton.FontSize = 18;
            app.ChooseImageButton.Position = [350 579 119 31];
            app.ChooseImageButton.Text = 'Choose Image';

            % Create Image
            app.Image = uiimage(app.UIFigure);
            app.Image.Position = [-3 677 138 128];
            app.Image.ImageSource = fullfile(pathToMLAPP, 'Images', 'backsideimg', '1_d0Ewp1f4c6tKmi3C_gzxRg.jpeg');

            % Create ogImage
            app.ogImage = uiimage(app.UIFigure);
            app.ogImage.Position = [89 338 237 201];

            % Create OriginalImageLabel
            app.OriginalImageLabel = uilabel(app.UIFigure);
            app.OriginalImageLabel.FontName = 'Berlin Sans FB';
            app.OriginalImageLabel.FontSize = 18;
            app.OriginalImageLabel.FontColor = [1 1 1];
            app.OriginalImageLabel.Position = [146 537 117 24];
            app.OriginalImageLabel.Text = 'Original Image';

            % Create compressedImage
            app.compressedImage = uiimage(app.UIFigure);
            app.compressedImage.Position = [497 328 237 201];

            % Create CompressedImageLabel
            app.CompressedImageLabel = uilabel(app.UIFigure);
            app.CompressedImageLabel.FontName = 'Berlin Sans FB';
            app.CompressedImageLabel.FontSize = 18;
            app.CompressedImageLabel.FontColor = [1 1 1];
            app.CompressedImageLabel.Position = [543 537 146 24];
            app.CompressedImageLabel.Text = 'Compressed Image';

            % Create CompressButton
            app.CompressButton = uibutton(app.UIFigure, 'push');
            app.CompressButton.ButtonPushedFcn = createCallbackFcn(app, @CompressButtonPushed, true);
            app.CompressButton.FontName = 'Berlin Sans FB';
            app.CompressButton.FontSize = 18;
            app.CompressButton.Position = [350 225 100 31];
            app.CompressButton.Text = 'Compress';

            % Create SelectacompressionqualityfactorSliderLabel
            app.SelectacompressionqualityfactorSliderLabel = uilabel(app.UIFigure);
            app.SelectacompressionqualityfactorSliderLabel.HorizontalAlignment = 'right';
            app.SelectacompressionqualityfactorSliderLabel.FontName = 'Berlin Sans FB';
            app.SelectacompressionqualityfactorSliderLabel.FontSize = 14;
            app.SelectacompressionqualityfactorSliderLabel.FontColor = [1 1 1];
            app.SelectacompressionqualityfactorSliderLabel.Position = [113 289 206 22];
            app.SelectacompressionqualityfactorSliderLabel.Text = 'Select a compression quality factor';

            % Create SelectacompressionqualityfactorSlider
            app.SelectacompressionqualityfactorSlider = uislider(app.UIFigure);
            app.SelectacompressionqualityfactorSlider.ValueChangedFcn = createCallbackFcn(app, @SelectacompressionqualityfactorSliderValueChanged, true);
            app.SelectacompressionqualityfactorSlider.FontColor = [1 1 1];
            app.SelectacompressionqualityfactorSlider.Position = [340 298 150 3];

            % Create CompressedImageCharacteristicsLabel_2
            app.CompressedImageCharacteristicsLabel_2 = uilabel(app.UIFigure);
            app.CompressedImageCharacteristicsLabel_2.FontName = 'Berlin Sans FB';
            app.CompressedImageCharacteristicsLabel_2.FontSize = 18;
            app.CompressedImageCharacteristicsLabel_2.FontAngle = 'italic';
            app.CompressedImageCharacteristicsLabel_2.FontColor = [1 1 1];
            app.CompressedImageCharacteristicsLabel_2.Position = [284 188 260 24];
            app.CompressedImageCharacteristicsLabel_2.Text = 'Compressed Image Characteristics';

            % Create EntropyLabel
            app.EntropyLabel = uilabel(app.UIFigure);
            app.EntropyLabel.FontName = 'Berlin Sans FB';
            app.EntropyLabel.FontSize = 18;
            app.EntropyLabel.FontColor = [1 1 1];
            app.EntropyLabel.Position = [27 152 72 24];
            app.EntropyLabel.Text = 'Entropy: ';

            % Create OriginalImageSizeLabel
            app.OriginalImageSizeLabel = uilabel(app.UIFigure);
            app.OriginalImageSizeLabel.FontName = 'Berlin Sans FB';
            app.OriginalImageSizeLabel.FontSize = 18;
            app.OriginalImageSizeLabel.FontColor = [1 1 1];
            app.OriginalImageSizeLabel.Position = [28 119 153 24];
            app.OriginalImageSizeLabel.Text = 'Original Image Size:';

            % Create CompressedImageSizeLabel
            app.CompressedImageSizeLabel = uilabel(app.UIFigure);
            app.CompressedImageSizeLabel.FontName = 'Berlin Sans FB';
            app.CompressedImageSizeLabel.FontSize = 18;
            app.CompressedImageSizeLabel.FontColor = [1 1 1];
            app.CompressedImageSizeLabel.Position = [30 87 183 24];
            app.CompressedImageSizeLabel.Text = 'Compressed Image Size:';

            % Create entropyDisplayValue
            app.entropyDisplayValue = uilabel(app.UIFigure);
            app.entropyDisplayValue.FontName = 'Berlin Sans FB';
            app.entropyDisplayValue.FontSize = 18;
            app.entropyDisplayValue.FontColor = [0.6902 0.2314 0.2588];
            app.entropyDisplayValue.Position = [235 152 44 24];
            app.entropyDisplayValue.Text = '0';

            % Create ogImageSizeDisplayValue
            app.ogImageSizeDisplayValue = uilabel(app.UIFigure);
            app.ogImageSizeDisplayValue.FontName = 'Berlin Sans FB';
            app.ogImageSizeDisplayValue.FontSize = 18;
            app.ogImageSizeDisplayValue.FontColor = [0.6902 0.2314 0.2588];
            app.ogImageSizeDisplayValue.Position = [235 119 44 24];
            app.ogImageSizeDisplayValue.Text = '0';

            % Create compressedImageSizeDisplayValue
            app.compressedImageSizeDisplayValue = uilabel(app.UIFigure);
            app.compressedImageSizeDisplayValue.FontName = 'Berlin Sans FB';
            app.compressedImageSizeDisplayValue.FontSize = 18;
            app.compressedImageSizeDisplayValue.FontColor = [0.6902 0.2314 0.2588];
            app.compressedImageSizeDisplayValue.Position = [235 87 44 24];
            app.compressedImageSizeDisplayValue.Text = '0';

            % Create EE421DIGITALANDANALOGSIGNALPROCESSINGINTELECOMMUNICATIONSLabel
            app.EE421DIGITALANDANALOGSIGNALPROCESSINGINTELECOMMUNICATIONSLabel = uilabel(app.UIFigure);
            app.EE421DIGITALANDANALOGSIGNALPROCESSINGINTELECOMMUNICATIONSLabel.FontName = 'Berlin Sans FB';
            app.EE421DIGITALANDANALOGSIGNALPROCESSINGINTELECOMMUNICATIONSLabel.FontSize = 16;
            app.EE421DIGITALANDANALOGSIGNALPROCESSINGINTELECOMMUNICATIONSLabel.FontColor = [1 1 1];
            app.EE421DIGITALANDANALOGSIGNALPROCESSINGINTELECOMMUNICATIONSLabel.Position = [158 763 569 22];
            app.EE421DIGITALANDANALOGSIGNALPROCESSINGINTELECOMMUNICATIONSLabel.Text = 'EE421 | DIGITAL AND ANALOG SIGNAL PROCESSING IN TELECOMMUNICATIONS';

            % Create SpecialthankstoLabel
            app.SpecialthankstoLabel = uilabel(app.UIFigure);
            app.SpecialthankstoLabel.FontName = 'Berlin Sans FB';
            app.SpecialthankstoLabel.FontSize = 14;
            app.SpecialthankstoLabel.FontColor = [1 1 1];
            app.SpecialthankstoLabel.Position = [586 65 110 22];
            app.SpecialthankstoLabel.Text = 'Special thanks to: ';

            % Create DrAliSeguMohamedHyderLabel
            app.DrAliSeguMohamedHyderLabel = uilabel(app.UIFigure);
            app.DrAliSeguMohamedHyderLabel.FontName = 'Berlin Sans FB';
            app.DrAliSeguMohamedHyderLabel.FontSize = 14;
            app.DrAliSeguMohamedHyderLabel.FontColor = [1 1 1];
            app.DrAliSeguMohamedHyderLabel.Position = [586 44 175 22];
            app.DrAliSeguMohamedHyderLabel.Text = 'Dr. Ali Segu Mohamed Hyder';

            % Create MsEvelynAmuLabel
            app.MsEvelynAmuLabel = uilabel(app.UIFigure);
            app.MsEvelynAmuLabel.FontName = 'Berlin Sans FB';
            app.MsEvelynAmuLabel.FontSize = 14;
            app.MsEvelynAmuLabel.FontColor = [1 1 1];
            app.MsEvelynAmuLabel.Position = [586 23 97 22];
            app.MsEvelynAmuLabel.Text = 'Ms. Evelyn Amu';

            % Create GROUP4Label
            app.GROUP4Label = uilabel(app.UIFigure);
            app.GROUP4Label.FontName = 'Berlin Sans FB';
            app.GROUP4Label.FontSize = 36;
            app.GROUP4Label.FontColor = [1 1 1];
            app.GROUP4Label.Position = [319 716 150 48];
            app.GROUP4Label.Text = 'GROUP 4';

            % Create Label2
            app.Label2 = uilabel(app.UIFigure);
            app.Label2.FontName = 'Berlin Sans FB';
            app.Label2.FontSize = 14;
            app.Label2.FontColor = [1 1 1];
            app.Label2.Position = [658 631 117 86];
            app.Label2.Text = {'MEMBERS:'; 'Jude Watimongo'; 'Marilyn Appenteng'; 'Fauzan Abdallah'; 'Abdul Sabit Ariff'; ''};

            % Create Unit1
            app.Unit1 = uilabel(app.UIFigure);
            app.Unit1.FontName = 'Berlin Sans FB';
            app.Unit1.FontSize = 18;
            app.Unit1.FontColor = [1 1 1];
            app.Unit1.Position = [278 119 27 24];
            app.Unit1.Text = 'KB';

            % Create Unit2
            app.Unit2 = uilabel(app.UIFigure);
            app.Unit2.FontName = 'Berlin Sans FB';
            app.Unit2.FontSize = 18;
            app.Unit2.FontColor = [1 1 1];
            app.Unit2.Position = [278 87 27 24];
            app.Unit2.Text = 'KB';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = JPEGCompressor_exported

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