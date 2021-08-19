avalanche_data = readtable('D:/UC DAVIS/CW3E/data/avalanche_data/avalanche_coords_datenum.csv');
alaska_data = avalanche_data(avalanche_data.state=="AK",1:5);
westUS_data = avalanche_data(avalanche_data.state~="AK",1:5);


%%

info = wmsinfo('https://worldwind26.arc.nasa.gov/wms/elev?');
layers = info.Layer;
srtm = refine(layers,'SRTM','SearchField','layername');

%% Plotting Western United States

latlim = [30 50];
lonlim = [-130 -100];
cellSize = dms2degrees([0,1,0]);
[ZA,RA] = wmsread(srtm,'Latlim',latlim,'Lonlim',lonlim, ...
   'CellSize',cellSize,'ImageFormat','image/tiff');
elevationLimits = [-1000 max(max(ZA))];
figure
worldmap(latlim,lonlim)
hold on
%geoshow(ZA,RA,'DisplayType','texturemap')
%demcmap(double(ZA))
hold on
S = shaperead('usastatelo.shp'); %
geoshow([S.Y],[S.X],'Color','b');
%contourm(double(ZA),RA,[0 0],'Color','k')
%c = colorbar;
%c.Label.String = 'Elevation (m)';
ax = gca;
ax.TitleFontSizeMultiplier = 1.4;

title({'Western United States 2015-2021'}, ...
    'Interpreter','none');

westUS_lat = westUS_data.lat;
westUS_lon = westUS_data.lon;

h = scatterm(westUS_lat,westUS_lon,40,'k','filled');
h.Children.MarkerFaceAlpha = .6;

%% Plotting Alaska 

latlim = [50 73];
lonlim = [-170 -140];
cellSize = dms2degrees([0,1,0]);
[ZA,RA] = wmsread(srtm,'Latlim',latlim,'Lonlim',lonlim, ...
   'CellSize',cellSize,'ImageFormat','image/tiff');
elevationLimits = [min(min(ZA)) max(max(ZA))];
figure
worldmap(latlim,lonlim)

geoshow(ZA,RA,'DisplayType','texturemap')
demcmap(double(ZA))
contourm(double(ZA),RA,[0 0],'Color','c')
colorbar

ax = gca;
ax.TitleFontSizeMultiplier = 1.4;

title({'Alaska 2015-2021'}, ...
    'Interpreter','none');

alaska_lat = alaska_data.lat;
alaska_lon = alaska_data.lon;

h = scatterm(alaska_lat,alaska_lon,40,'k','filled');
h.Children.MarkerFaceAlpha = .6;
