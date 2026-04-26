#!/bin/bash

# Ollama Model Management Script
# This script helps manage local Ollama models: listing, pulling, and pruning.

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  list      List all installed models"
    echo "  pull      Pull/Update a specific model"
    echo "  update    Update all currently installed models"
    echo "  remove    Remove a specific model"
    echo "  prune     Interactively remove models"
    echo "  help      Show this help message"
}

function check_ollama() {
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}Error: Ollama is not installed or not in PATH.${NC}"
        exit 1
    fi
}

function list_models() {
    echo -e "${GREEN}Installed Ollama Models:${NC}"
    ollama list
}

function pull_model() {
    if [ -z "$1" ]; then
        read -p "Enter model name to pull: " model_name
    else
        model_name=$1
    fi
    
    if [ -n "$model_name" ]; then
        echo -e "${YELLOW}Pulling model: $model_name...${NC}"
        ollama pull "$model_name"
    else
        echo -e "${RED}No model name provided.${NC}"
    fi
}

function update_all_models() {
    echo -e "${YELLOW}Updating all installed models...${NC}"
    models=$(ollama list | awk 'NR>1 {print $1}')
    for model in $models; do
        echo -e "${YELLOW}Updating $model...${NC}"
        ollama pull "$model"
    done
    echo -e "${GREEN}All models updated.${NC}"
}

function remove_model() {
    if [ -z "$1" ]; then
        read -p "Enter model name to remove: " model_name
    else
        model_name=$1
    fi
    
    if [ -n "$model_name" ]; then
        echo -e "${RED}Removing model: $model_name...${NC}"
        ollama rm "$model_name"
    else
        echo -e "${RED}No model name provided.${NC}"
    fi
}

function prune_models() {
    echo -e "${YELLOW}Pruning models (Interactive)...${NC}"
    models=$(ollama list | awk 'NR>1 {print $1}')
    for model in $models; do
        read -p "Keep $model? [Y/n]: " choice
        case "$choice" in 
          n|N ) 
            echo -e "${RED}Removing $model...${NC}"
            ollama rm "$model"
            ;;
          * ) 
            echo -e "${GREEN}Keeping $model.${NC}"
            ;;
        esac
    done
}

# Main execution
check_ollama

case "$1" in
    list)
        list_models
        ;;
    pull)
        pull_model "$2"
        ;;
    update)
        update_all_models
        ;;
    remove)
        remove_model "$2"
        ;;
    prune)
        prune_models
        ;;
    help|*)
        show_help
        ;;
esac
