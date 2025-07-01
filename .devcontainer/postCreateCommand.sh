#!/bin/bash

# Install Python dependencies
pip install --upgrade pip
pip install flake8 pylint

# Install any assignment-specific requirements
if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi

# Create a message for students
echo "Ambiente listo! Chequeo de sintaxis de Python habiltado."
echo "Se deshabilitaron asistentes AI y autocompletado de código para esta tarea."