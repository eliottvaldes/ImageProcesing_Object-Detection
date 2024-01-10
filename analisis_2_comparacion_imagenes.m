%{
    Programa: "Identificación de objetos en una imagen, dibujar bordes y guardar imagen"
    Descripción: Programa que identifica los objetos en una imagen, dibuja los bordes
    de los objetos y guarda la imagen donde se compara la imagen original y los bordes.
    
    Código por: Valdés Luis Eliot Fabián    
    Imagenes por: Padilla Rodriguez Ethel
%}

clc; warning off all; clear; close all;

% Define el directorio donde se encuentran las imagenes
folderPath = './images';
objectsPath = './imagesObjects';

% verificamos que exista el directorio donde se guardaran las imagenes, si no existe lo creamos
if ~exist(objectsPath, 'dir')
    mkdir(objectsPath);
end

% Obtenemos las imagenes del directorio
images = dir(fullfile(folderPath, '*.jpg'));


% Procesar cada imagen
for i = 1:length(images)
    % Obtenemos el path de la imagen
    imagePath = fullfile(folderPath, images(i).name);
    % Leemos la imagen
    I = imread(imagePath);
    % redimencionamos la imagen
    I = imresize(I, 0.2, 'bicubic');
    % variable auxiliar para dibujar bordes identificados
    original = I;

    % Convertir a doble
    I = im2double(I);
    % Resaltamos bordes
    filter_parks = firpm(16, [0 0.1 0.4 1], [0 0 1 1]);
    filter_parks = ftrans2(filter_parks);
    I = I + filter2(filter_parks, rgb2gray(I));
    I = min(max(I * 1.1, 0), 1); % Aumento de saturación y rango [0, 1]

    %% Preprocesamiento y segmentación
    % Binarización y eliminación de ruido
    I = imbinarize(wiener2(im2gray(I), [5 5]));
    % Eliminación de ruido (objetos pequeños)
    I = bwareaopen(I, 900);
    % Operaciones morfológicas para eliminar ruido y cerrar huecos
    SE = strel('disk', 4);
    I = imclose(I, SE);
    I = bwareaopen(I, 500);
    I = imerode(I, SE);
    % Invertir imagen
    I = ~I;

    % Etiquetar y filtrar objetos
    [L, num] = bwlabel(I);
    % obtener las propiedades de los objetos, en este caso el area
    propiedades = regionprops(L, 'Area');
    % definimos una variable auxiliar para filtrar los objetos
    I_filtrada = false(size(I));
    % Filtro para eliminar los con area [2000, ...]
    for k = 1:num
        if propiedades(k).Area >= 2000
            I_filtrada = I_filtrada | (L == k);
        end
    end
    I = I_filtrada;

    % Obtener bordes y objetos
    [B, L] = bwboundaries(I, 8, "holes");
    % Dibujar bordes
    objetos = label2rgb(L, @jet, [.5 .5 .5]);
    fig = figure;
    imshowpair(original, objetos, "montage");
    title("Imagen original y bordes");
    [~, imageName, ~] = fileparts(images(i).name);
    % Guardar imagen donde se compara la imagen original y los bordes
    savePath = fullfile(objectsPath, [imageName '.jpg']);
    saveas(fig, savePath);
    close(fig);

end