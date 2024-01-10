%{
    Programa: "Procesamiento de imágenes para la detección de objetos. Caracterización de objetos y creación de un dataset."    
    Descripción: Programa que permite procesar una carpeta de imágenes para analizarlas 
    de forma independiente con el fin de la detección de objetos dentro de las mismas y 
    la caracterización de cada uno de los objetos detectados.
    Obtiene las características de los objetos: área, perímetro y circularidad. 
    Guarda las características en un archivo CSV que sirve como dataset para su posterior
    análisis.

    Código por: Valdés Luis Eliot Fabián
    Imagenes por: Padilla Rodriguez Ethel    
%}

clc; warning off all; clear; close all;

% Define el directorio donde se encuentran las imagenes
folderPath = './images';

images = dir(fullfile(folderPath, '*.jpg'));

% verificar si la carpeta datasets existe, de lo contrario la crea
if ~exist('./datasets', 'dir')
    mkdir('./datasets');
end

% Abrir/Crear archivo CSV
fid = fopen('./datasets/data.csv', 'w');
% Definimos los encabezados del archivo CSV
fprintf(fid, '%s,%s,%s,%s\n', 'Imagen', 'Area', 'Perimetro', 'Circularidad');

% Procesar cada imagen dentro de la carpeta images
for i = 1:length(images)
    imagePath = fullfile(folderPath, images(i).name);

    I = imread(imagePath);    
    % redimencionamos la imagen
    I = imresize(I, 0.2, 'bicubic'); % Simplificado
    original = I;

    % Convertir a doble y resaltar bordes
    I = im2double(I);
    filter_parks = firpm(16, [0 0.1 0.4 1], [0 0 1 1]);
    filter_parks = ftrans2(filter_parks);
    I = I + filter2(filter_parks, rgb2gray(I));
    I = min(max(I * 1.1, 0), 1);

    % Preprocesamiento y segmentación
    I = imbinarize(wiener2(im2gray(I), [5 5]));
    I = bwareaopen(I, 900);
    SE = strel('disk', 4);
    I = imclose(I, SE);
    I = bwareaopen(I, 500);
    I = imerode(I, SE);
    I = ~I;

    % Etiquetar y filtrar objetos con area [2000, ...]
    [L, num] = bwlabel(I);
    propiedades = regionprops(L, 'Area');
    I_filtrada = false(size(I));
    for k = 1:num
        if propiedades(k).Area >= 2000
            I_filtrada = I_filtrada | (L == k);
        end
    end
    I = I_filtrada;


    % Procesamiento y visualización
    figure(); imshow(original); hold on;

    for k = 1:num
        objeto = (L == k) & I_filtrada;
        if any(objeto(:))
            % Obtención de características
            area = bwarea(objeto);
            perimetro = sum(bwperim(objeto, 8), 'all');
            circularidad = (4 * pi * area) / (perimetro^2);

            %% Guardar caracteristicas en archivo CSV
            fprintf(fid, '%s,%f,%f,%f\n', images(i).name, area, perimetro, circularidad);

            % Dibujo y etiquetas
            boundary = bwboundaries(objeto);
            plot(boundary{1}(:,2), boundary{1}(:,1), 'g', 'LineWidth', 2);
            stats = regionprops(objeto, 'Centroid');
            texto = sprintf('Área: %.2f, Perímetro: %.2f, Circularidad: %.2f', area, perimetro, circularidad);
            text(stats.Centroid(1), stats.Centroid(2), texto, 'EdgeColor', 'b', 'BackgroundColor', 'white');
        end
    end

    hold off;

    % Esperar un tiempo antes de cerrar la figura actual y continuar con la siguiente
    pause(2);
    % Cerrar la figura actual antes de la siguiente iteracionn
    close(gcf);

end

% Cerrar archivo CSV
fclose(fid);
