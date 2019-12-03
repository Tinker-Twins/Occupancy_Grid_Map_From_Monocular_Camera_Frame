% LOAD AND USE THE TRAINED DNN:

% Deep Neural Network
Trained_DNN = 'Trained_DNN';

% Load the DNN
Data = load(Trained_DNN);
DNN = Data.net;


% FIRST PERSON VIEW OF IMAGE (CAMERA PERSPECTIVE):

% Load and Process Sample Camera Frame
Image = imread('Test_Frame.png'); % Read the image
figure
title('Test Frame')
imshow(Image) % Display the test image
[Free_Space,Scores,All_Scores] = semanticseg(Image,DNN); % Semantic segmentation of image
Processed_Image = labeloverlay(Image,Free_Space,'IncludedLabels',"Road"); % Overlay free space on the image
figure
title('Free Space Prediction [FPV]')
imshow(Processed_Image) % Display free space and image

% Compute Free Space Confidence Level (Probability)
Road_Class_ID = 4; % Class ID is the index of "Road" in the array used for training the DNN
Free_Space_Confidence = All_Scores(:,:,Road_Class_ID); % Use DNN's output score for road as free space confidence
figure
imagesc(Free_Space_Confidence) % Display the free space confidence
title('Free Space Confidence Scores [FPV]')
colorbar



% BIRD'S EYE VIEW OF IMAGE (VEHICLE PERSPECTIVE):

Sensor = MonoCameraSensor(); % Create monocular camera

% Define Bird's-Eye-View Transformation Parameters
DistAheadOfSensor = 20; % Look 20 m in front
SpaceToOneSide    = 3;  % Look 3 m to right and left
BottomOffset      = 0;  
OutView = [BottomOffset, DistAheadOfSensor, -SpaceToOneSide, SpaceToOneSide];
OutImageSize = [NaN, 256]; % Output image width in pixels (Height is chosen automatically to preserve units per pixel ratio)
BirdsEyeConfig = birdsEyeView(Sensor,OutView,OutImageSize);

% Resize Image and Free Space Estimate to Size of Monocular Camera
ImageSize = Sensor.Intrinsics.ImageSize;
Image = imresize(Image,ImageSize);
Free_Space_Confidence = imresize(Free_Space_Confidence,ImageSize);

% Transform Image and Free Space Confidence Scores Into Bird's-Eye View
ImageBEV = transformImage(BirdsEyeConfig,Image);
FreeSpaceBEV = transformImage(BirdsEyeConfig,Free_Space_Confidence); 

% Display Image Frame in Bird's-Eye View
figure
title('Bird''s Eye View')
imshow(ImageBEV)

% Display Free Space Confidence
figure
imagesc(FreeSpaceBEV)
title('Free Space Confidence Scores [BEV]')



% GENERATE OCCUPANCY GRID BASED ON FREE SPACE CONFIDENCE

% Define Dimensions and Resolution of the Occupancy Grid
GridX = DistAheadOfSensor; % X-Dimension (in metres)
GridY = 2 * SpaceToOneSide; % Y-Dimension (in metres)
CellSize = 0.25; % Resolution (in metres)

% Create the Occupancy Grid
OccupancyGrid = CreateOccupancyGridFromFreeSpaceEstimate(...
FreeSpaceBEV, BirdsEyeConfig, GridX, GridY, CellSize);

% Create Bird's-Eye Plot
BEP = birdsEyePlot('XLimits',[0 DistAheadOfSensor],'YLimits', [-5 5]);

% Add Occupancy Grid to Bird's-Eye Plot
hold on
[NumCellsY,NumCellsX] = size(OccupancyGrid);
X = linspace(0, GridX, NumCellsX);
Y = linspace(-GridY/2, GridY/2, NumCellsY);
h = pcolor(X,Y,OccupancyGrid);
title('Occupancy Grid Map')
colorbar
delete(legend)

% Make Occupancy Grid Visualization Transparent and Remove Grid Lines
h.FaceAlpha = 0.5;
h.LineStyle = 'none';