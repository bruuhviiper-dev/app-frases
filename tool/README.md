# Ferramentas de conteúdo

## Classificador automático de frases (IA)

`classify_phrases.dart` recebe frases soltas e usa a **API do Claude** para
classificá-las na categoria certa, marcar conteúdo proibido e evitar repetidas.
Gera `content/generated_phrases.json`, pronto para publicar como conteúdo remoto
(o app mescla pelo `id`, sem duplicar).

### Como usar

1. **Catálogo de categorias** (`tool/categories.json`): id + nome de todas as
   categorias do app. Para regenerar depois de criar categorias novas:
   ```powershell
   # extrai id/name de lib/data/phrases.dart e phrases_extra.dart
   ```
   (ou edite o JSON à mão).

2. **Chave da API** (não comite a chave):
   ```powershell
   $env:ANTHROPIC_API_KEY = "sk-ant-..."   # PowerShell
   export ANTHROPIC_API_KEY="sk-ant-..."   # bash
   ```

3. **Frases de entrada**: edite `tool/input_phrases.txt` (uma por linha).

4. **Rode**:
   ```bash
   dart run tool/classify_phrases.dart tool/input_phrases.txt
   ```

5. Confira `content/generated_phrases.json`. As frases marcadas como proibidas e
   os IDs inválidos são listados no terminal e descartados.

### Dedup contra o conteúdo existente (opcional)

Se existir `content/existing_phrases.txt` (uma frase por linha), o classificador
também evita repetir frases que já estão no app.

### Observações

- Modelo padrão: `claude-haiku-4-5-20251001` (rápido/barato). Para julgamento
  mais rigoroso, troque por `claude-sonnet-4-6` no topo do script.
- O `id` é o que define a categoria no app. O classificador só usa IDs do
  catálogo, então as frases caem sempre numa categoria existente.
