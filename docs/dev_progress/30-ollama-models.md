# Ollama Model Guide

Choosing the right model is crucial for the performance and intelligence of your Hermes Agent.

## Recommended Models

For the best experience with Hermes Agent, we recommend models from the **Hermes** and **Llama** families.

| Model Name | Size | Recommended RAM/VRAM | Use Case |
| :--- | :--- | :--- | :--- |
| **Hermes 3 (Llama 3.1 8B)** | 4.7 GB | 8GB+ | **Recommended**. Balanced, fast, and highly capable. |
| **Llama 3.1 8B** | 4.7 GB | 8GB+ | Great general-purpose model. |
| **Hermes 2 Pro (Llama 3 8B)** | 4.7 GB | 8GB+ | Optimized for tool use and function calling. |
| **Mistral 7B** | 4.1 GB | 8GB+ | Strong alternative to Llama. |
| **Llama 3.1 70B** | 40 GB | 48GB+ (2x 3090/4090) | High-end intelligence, requires significant VRAM. |

## RAM and VRAM Advice

The amount of memory (VRAM for GPUs, RAM for CPUs) determines how large a model you can run.

1.  **Small Models (7B - 8B)**:
    - Minimum: 8GB RAM/VRAM.
    - Performance: Very fast on most modern GPUs (RTX 3060+, Apple M-series).
    - Capabilities: Excellent for most agent tasks, including chatting and simple tool use.

2.  **Medium Models (13B - 34B)**:
    - Minimum: 16GB - 24GB RAM/VRAM.
    - Performance: Decent speed on mid-to-high end GPUs.
    - Capabilities: Better reasoning and complex instruction following.

3.  **Large Models (70B+)**:
    - Minimum: 40GB+ RAM/VRAM.
    - Performance: Slower unless using high-end data center GPUs or multiple consumer GPUs.
    - Capabilities: Top-tier reasoning, best for complex problem solving.

> **Tip**: If you don't have enough VRAM, Ollama will automatically offload parts of the model to your system RAM, but this will significantly slow down response times.

## Pulling Models

To use a model, you must first "pull" it using the Ollama CLI.

### Basic Command
```bash
ollama pull <model_name>
```

### Examples
```bash
# Pull the latest Hermes 3 model
ollama pull hermes3

# Pull the standard Llama 3.1
ollama pull llama3.1

# Pull a specific version (e.g., Llama 3.1 70B)
ollama pull llama3.1:70b
```

## Configuring Hermes to Use a Specific Model

Once a model is pulled, you can tell Hermes to use it in several ways:

1.  **Via Command Line**:
    ```bash
    hermes chat --model hermes3
    ```

2.  **Via Environment Variable**:
    Set `HERMES_MODEL` in your `.zshrc` or `.bashrc`:
    ```bash
    export HERMES_MODEL="hermes3"
    ```

3.  **Via Config File**:
    Update `~/.hermes/config.yaml` (see [Config Reference](50-config-reference.md)).

## Performance Tuning

- **Context Window**: Most Llama 3.1 models support up to 128k context, but Ollama might default to a smaller window (e.g., 2k or 8k). You can adjust this in your `Modelfile` or via Hermes config if supported.
- **Quantization**: By default, `ollama pull` gets the `q4_0` or `q4_K_M` version. If you need higher precision (e.g., `q8_0`) or lower memory usage (e.g., `q2_K`), check the [Ollama Library](https://ollama.com/library) for specific tags.
