# Repositorio de Análisis y Modelado EPH

Este repositorio contiene una serie de scripts en Stata y un cuaderno de Jupyter (Python) para el análisis de la reforma del PRS usando la Encuesta Permanente de Hogares (EPH). Se realizan tareas de limpieza de datos, análisis exploratorio, modelado (modelos lineales, LASSO, XGBoost, etc.), simulaciones y generación de gráficos. El objetivo es analizar distintos aspectos relacionados con la pobreza, inclusión y exclusión en la EPH.

## Contenidos

- **00 - Run all scripts.do**  
  Script principal que ejecuta de manera secuencial todos los demás scripts. Útil para correr todo el flujo de trabajo de principio a fin. Modificar las globales para que se correspondan con el directorio en tu computadora.

- **01 - Limpia base.do**  
  Script encargado de la limpieza y preparación de la base de datos. Realiza filtrados, manejo de valores perdidos y transformación de variables necesarias para los análisis posteriores.

- **02 - Modelos lineales y Lasso.do**  
  Script para ejecutar modelos lineales y de regresión LASSO utilizando Stata. Permite validar y comparar diferentes especificaciones de modelos.

- **03 - ML models.ipynb**  
  Cuaderno de Jupyter que implementa modelos de machine learning en Python, incluyendo regresión lineal, XGBoost y otras técnicas. Se usa para explorar métodos predictivos sobre los datos de la EPH.

- **06 - Analisis EPH inclusion y exclusion.do**  
  Script que realiza el análisis de errores de inclusión y exclusión dentro de la EPH, proporcionando insights sobre la distribución de la pobreza y otros indicadores sociales.

- **07 - Simulación EPH pobreza.do**  
  Script que ejecuta una simulación de escenarios de pobreza basados en los datos de la EPH. Permite evaluar el impacto de los distintos procesos de selección.

- **08 - Quintiles EPH.do**  
  Script para el análisis de quintiles de la población a partir de los datos de la EPH. Se utiliza para segmentar y comparar el impacto redistributivo en distintos grupos socioeconómicos.

- **09 - Graficos.do**  
  Script dedicado a la generación de gráficos y visualizaciones de los resultados obtenidos en los análisis anteriores. Facilita la interpretación y comunicación de los hallazgos.

## Requisitos

### Para los scripts en Stata

- **Stata** (versión 14 o superior recomendada)  
  Asegúrese de tener Stata instalado y configurado para ejecutar archivos `.do`.
- Librerías necesarias (pueden instalarse utilizando `ssc install`):
  - `winsor`
  - ¿Falta alguna?

### Para el cuaderno de Jupyter

- **Python 3.x**  
- **Jupyter Notebook** o **JupyterLab**  
- Librerías necesarias (puede instalarse utilizando `pip`):
  - `pandas`
  - `numpy`
  - `scikit-learn`
  - `xgboost`
  - `matplotlib`
  - Otras dependencias según se requiera
