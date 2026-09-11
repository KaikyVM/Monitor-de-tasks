# Como contribuir

## Antes de abrir um pull request

1. Crie uma branch com um nome objetivo, por exemplo `feat/status-filter` ou `fix/cognito-redirect`.
2. Mantenha cada pull request focado em uma única mudança.
3. Rode as validações relevantes:

   ```bash
   cd src/frontend && npm run lint && npm run build
   pytest
   ```

4. Não inclua arquivos `.env`, credenciais, tokens, estados Terraform ou `*.tfvars` com valores reais.
5. Descreva o que mudou, como foi validado e qualquer impacto de infraestrutura.

## Convenções

- Prefira commits pequenos e descritivos usando `feat:`, `fix:`, `docs:`, `chore:` ou `refactor:`.
- Use inglês em nomes de arquivos, código e mensagens de commit; a documentação pode ser em português.
- Formate mudanças de Terraform com `terraform fmt` antes de enviar.
