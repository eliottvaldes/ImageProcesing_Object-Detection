%{
    Programa: "BUSCADOR DE SIMILITUDES EN IMAGENES"    
    Descripción: Programa que permite seleccionar una imagen y encontrar las 3 más similares
    a la imagen seleccionada de un conjunto de imagenes. Para ello, se utiliza un archivo CSV
    con las características de cada imagen (Area, Perimetro, Circularidad) y se calcula la
    similitud entre la imagen seleccionada y cada una de las demás imagenes del conjunto.
    Para calcular la similitud, se toma en consideración el número de objetos en cada imagen.
    Finalmente, se ordenan las imagenes por similitud de forma descendente y se muestran las
    3 más similares a la imagen seleccionada.

    Código por: Valdés Luis Eliot Fabián
    Imagenes por: Padilla Rodriguez Ethel    
%}


clc; warning off all; clear; close all;

% ejecuta la función para crear la GUI y llevar a cabo el proceso de búsqueda de similitudes
image_similarity_finder();

% Función para crear la GUI y llevar a cabo el proceso de búsqueda de similitudes
function image_similarity_finder
    % Cargar datos del CSV solo una vez
    persistent data;
    if isempty(data)
        data = readtable('./datasets/data.csv');
    end
    
    % Crear GUI solo si aún no existe
    if isempty(findall(0, 'Type', 'Figure', 'Name', 'Buscador de similitudes'))
        fig = uifigure('Name', 'Buscador de similitudes en imagenes', 'Position', [100 100 600 400]);
        uibutton(fig, 'push', 'Text', 'Selecciona la imagen', 'Position', [250, 350, 100, 22], 'ButtonPushedFcn', @(btn, event) selectImage(data));
    end
end

% Función para seleccionar una imagen y encontrar las 3 más similares
% @param data: tabla con los datos de las imagenes (features del CSV)
function selectImage(data)
    % Abrir ventana para seleccionar imagen
    [file, path] = uigetfile('./images/*.jpg');
    if isequal(file, 0)
        return;
    end
    % Leer imagen seleccionada por el usuario
    selectedImage = imread(fullfile(path, file));

    % Mostrar imagen seleccionada y preparar para imágenes similares
    figure('Name', 'Imagen seleccionada y similares', 'NumberTitle', 'off');
    % Colocar la imagen seleccionada en un subplot para su visualización
    ax1 = subplot(2, 3, 2);
    imshow(selectedImage, 'Parent', ax1);
    title(ax1, 'Seleccion');

    % Obtener las imagenes similares
    similarImages = findSimilarImages(file, data);
    % mapeamos las imagenes y las colocamos en un subplot para su visualizacion
    for i = 1:length(similarImages)
        ax = subplot(2, 3, i+3);
        %imshow(imread(fullfile('./imagesObjects', similarImages{i})), 'Parent', ax); % Imagen con objetos detectados. OJO, verifica que exista en la carpeta
        imshow(imread(fullfile('./images', similarImages{i})), 'Parent', ax); % Imagen original
        title(ax, ['Similar ' num2str(i)]);
    end
end


% Función para encontrar las n imágenes similares a la imagen seleccionada (n = 3 por defecto)
% @param selectedFile: nombre de la imagen seleccionada
% @param data: tabla con los datos de las imagenes (features del CSV)
% @return similarImages: arreglo con los nombres de las imagenes similares
function similarImages = findSimilarImages(selectedFile, data)
    % Obtener las características de la imagen seleccionada por el usuario dentro de la tabla de datos
    selectedFeatures = data(strcmp(data.Imagen, selectedFile), :);
    % obtener la lista de imagenes únicas
    uniqueImages = unique(data.Imagen);
    % Eliminar la imagen seleccionada de la lista de imagenes
    uniqueImages(strcmp(uniqueImages, selectedFile)) = [];
    % Calcular la similitud de la imagen seleccionada con todas las demás
    similarityScores = arrayfun(@(x) calculateSimilarity(selectedFeatures, data(strcmp(data.Imagen, uniqueImages{x}), :)), 1:length(uniqueImages));

    % Ordena las imagenes por similitud de forma descendente para obtener las 3 más similares
    [~, idx] = sort(similarityScores, 'descend');
    % Obtenemos los primeros 3 elementos del arreglo ordenado y los devolvemos
    similarImages = uniqueImages(idx(1:3));
end


% Función para calcular la similitud entre dos imagenes utilizando las características de cada una (Area, Perimetro, Circularidad)
% NOTA: Toma en consideración el número de objetos en cada imagen
% @param features1: características de la imagen 1 (Imagen seleccionada por el usuario)
% @param features2: características de la imagen 2 (Imagen de la lista de imagenes únicas)
% @return score: puntuación de similitud entre las dos imagenes
function score = calculateSimilarity(features1, features2)
    % Comparación del número de objetos en cada imagen
    numObjects1 = size(features1, 1);
    numObjects2 = size(features2, 1);
    objectCountDifference = abs(numObjects1 - numObjects2);

    % Penalización por diferencias en el número de objetos. Podemos ajustar el peso de la penalización
    objectCountPenalty = objectCountDifference * 0.025;

    % Usamos el número de objetos más pequeño para calcular la similitud 
    numObjects = min(numObjects1, numObjects2);
    if numObjects == 0
        score = 0 - objectCountPenalty;
        return;
    end

    % Calcula la diferencia entre las características de cada objeto de la imagen 1 y la imagen 2
    % Para este apartado usamos la función de distancia de Manhattan
    diffArea = sum(abs(features1.Area(1:numObjects) - features2.Area(1:numObjects)) ./ max(features1.Area(1:numObjects), features2.Area(1:numObjects)));
    diffPerimeter = sum(abs(features1.Perimetro(1:numObjects) - features2.Perimetro(1:numObjects)) ./ max(features1.Perimetro(1:numObjects), features2.Perimetro(1:numObjects)));
    diffCircularity = sum(abs(features1.Circularidad(1:numObjects) - features2.Circularidad(1:numObjects)) ./ max(features1.Circularidad(1:numObjects), features2.Circularidad(1:numObjects)));

    % Calcula la puntuación con la penalización aplicada y la devuelve
    score = 1 - ((diffArea + diffPerimeter + diffCircularity) / (3 * numObjects)) - objectCountPenalty;
end
