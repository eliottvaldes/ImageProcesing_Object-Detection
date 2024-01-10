%{
    Programa: "Caracterización de objetos"
    Descripción: Programa que permite identificar y caracterizar objetos
    en una imagen. Se utilizan diferentes técnicas de preprocesamiento, procesamiento
    y segmentación para identificar los diferentes objetos en la imagen y dibujar
    sus bordes.
    
    Código por: Valdés Luis Eliot Fabián    
    Imagenes por: Padilla Rodriguez Ethel
%}


clc, clear, warning off all, close all;

% definimos el nombre de la imagen a procesar
% para cambiar la imagen, cambiar el nombre de la variable por el nombre una imagen existente
imageName = 'img_23';

% Lectura de la imagen
I = imread("images/" + imageName + ".jpg");

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
    disp(propiedades(k).Area);
    if propiedades(k).Area >= 2000
        I_filtrada = I_filtrada | (L == k);
    end
end
I = I_filtrada;


%% Procesamiento y visualización
figure(); imshow(original); hold on;

% mapeo de objetos en la imagen original y resaltado de bordes
for k = 1:num
    objeto = (L == k) & I_filtrada;
    if any(objeto(:))        
        % Dibujamos el borde de cada objeto
        boundary = bwboundaries(objeto);
        plot(boundary{1}(:,2), boundary{1}(:,1), 'g', 'LineWidth', 2);
    end
end

hold off;