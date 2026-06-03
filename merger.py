import os
import pathspec

# Configurações
IGNORE_FILE = 'merger.ignore'
OUTPUT_FILE = 'contexto_monografia.txt'

def load_gitignore_patterns(gitignore_path):
    if os.path.exists(gitignore_path):
        with open(gitignore_path, 'r') as f:
            return pathspec.PathSpec.from_lines('gitwildmatch', f)
    return pathspec.PathSpec.from_lines('gitwildmatch', [])

def generate_tree(root_dir, spec, prefix=""):
    tree_str = ""
    try:
        items = os.listdir(root_dir)
        # Filtra e ordena: diretórios primeiro, depois arquivos
        items.sort(key=lambda x: (not os.path.isdir(os.path.join(root_dir, x)), x.lower()))
        
        entries = []
        for item in items:
            path = os.path.join(root_dir, item)
            rel_path = os.path.relpath(path, start=os.getcwd())
            
            # Normaliza para o formato Linux/Git (barras)
            rel_path_unix = rel_path.replace("\\", "/")

            # Pula se estiver na lista de ignore ou se for o próprio script/output
            if spec.match_file(rel_path_unix) or item in [OUTPUT_FILE, 'merger.py', '.git']:
                continue
            entries.append(item)

        for i, item in enumerate(entries):
            path = os.path.join(root_dir, item)
            is_last = (i == len(entries) - 1)
            connector = "└── " if is_last else "├── "
            
            tree_str += f"{prefix}{connector}{item}\n"
            
            if os.path.isdir(path):
                extension = "    " if is_last else "│   "
                tree_str += generate_tree(path, spec, prefix + extension)
    except PermissionError:
        pass
    return tree_str

def merge_files():
    spec = load_gitignore_patterns(IGNORE_FILE)
    
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as outfile:
        # 1. Escreve a Árvore de Diretórios
        outfile.write("=== ESTRUTURA DO PROJETO ===\n")
        outfile.write(".\n")
        outfile.write(generate_tree('.', spec))
        outfile.write("\n" + "="*50 + "\n\n")
        
        # 2. Escreve o Conteúdo dos Arquivos
        for root, dirs, files in os.walk('.'):
            # Filtra diretórios ignorados para não entrar neles
            dirs[:] = [d for d in dirs if not spec.match_file(os.path.relpath(os.path.join(root, d), start='.').replace("\\", "/"))]
            dirs[:] = [d for d in dirs if d not in ['.git', '__pycache__', 'node_modules']] # Segurança extra

            for file in files:
                if file in [OUTPUT_FILE, 'merger.py', IGNORE_FILE]:
                    continue

                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, start='.').replace("\\", "/")

                if spec.match_file(rel_path):
                    continue

                try:
                    with open(file_path, 'r', encoding='utf-8') as infile:
                        content = infile.read()
                        outfile.write(f"--- INICIO ARQUIVO: {rel_path} ---\n")
                        outfile.write(content)
                        outfile.write(f"\n--- FIM ARQUIVO: {rel_path} ---\n\n")
                        print(f"Adicionado: {rel_path}")
                except (UnicodeDecodeError, PermissionError):
                    print(f"Ignorado (binário ou erro): {rel_path}")

if __name__ == "__main__":
    print("Iniciando geração do contexto...")
    merge_files()
    print(f"\nSucesso! Arquivo '{OUTPUT_FILE}' gerado.")