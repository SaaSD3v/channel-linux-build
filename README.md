# Moto G7 Play (channel) — Debian rootfs

Esta branch gera o rootfs Debian do Channel separadamente.

O workflow é `.github/workflows/rootfs.yml` e o artifact principal é `channel-debian-rootfs`.

## O que este build faz

A run usa os arquivos já mantidos no repositório:

- `scripts/build-kernel.sh`;
- `scripts/build-rootfs.sh`;
- `config/channel-mainline.config`;
- conteúdo de `rootfs/`.

O kernel é compilado dentro da própria run porque o rootfs precisa do release, dos módulos e do initramfs compatíveis. Esse kernel é uma dependência interna deste workflow; o artifact desta branch continua focado no rootfs.

## Artifact `channel-debian-rootfs`

Ele é mantido por 14 dias e contém:

- `debian-channel-rootfs.ext4.zst` — imagem ext4 final do Debian, comprimida para download;
- `initrd.img-*` — initramfs produzido para o kernel usado na mesma run;
- `build-info.txt` — registra suite, kernel release, label do rootfs e modo de autenticação selecionado;
- `SHA256SUMS.rootfs` — hashes dos arquivos finais do rootfs.

O workflow não publica `Image.gz`, DTB, lk2nd ou DTBO como artifacts desta branch.

## Campos de `Run workflow`

Ao abrir **Actions → Build Debian rootfs → Run workflow**, use a branch `main`. O launcher da `main` faz checkout da branch `rootfs` automaticamente.

### `ssh_auth`

Escolhe como o rootfs será preparado para acesso:

| Valor | Resultado |
| --- | --- |
| `generated-key` | Gera uma chave Ed25519 nova para a run e publica a chave privada/pública em `channel-rootfs-ssh-test-key`. |
| `public-key-input` | Usa a chave pública colada no campo `ssh_public_key`. Não gera chave privada para download. |
| `public-key-secret` | Usa o secret `SSH_PUBLIC_KEY`. Não gera chave privada para download. |
| `generated-password` | Gera uma senha nova para a run e publica `channel-rootfs-ssh-password`. |
| `password-secret` | Usa o secret `SSH_PASSWORD`. A senha não é publicada como artifact. |
| `generated-key+generated-password` | Gera uma chave e uma senha. Publica os dois artifacts temporários. |
| `public-key-input+password-secret` | Usa a chave do campo `ssh_public_key` junto com o secret `SSH_PASSWORD`. Não publica credenciais. |
| `public-key-secret+password-secret` | Usa `SSH_PUBLIC_KEY` e `SSH_PASSWORD` dos Secrets. Não publica credenciais. |
| `disabled` | Gera o rootfs com o serviço SSH desativado. Não publica credential artifact. |

O padrão do disparo manual é `generated-key`.

### `ssh_public_key`

Campo usado somente pelos modos:

- `public-key-input`;
- `public-key-input+password-secret`.

Cole nele a linha completa da chave pública, por exemplo uma linha iniciada por `ssh-ed25519`.

Esse campo não recebe chave privada.

## Secrets opcionais

O workflow reconhece:

- `SSH_PUBLIC_KEY` — usado por `public-key-secret` e `public-key-secret+password-secret`;
- `SSH_PASSWORD` — usado por `password-secret`, `public-key-input+password-secret` e `public-key-secret+password-secret`.

Se um modo que exige um desses Secrets for selecionado e o Secret não existir, a run falha em vez de gerar outra credencial silenciosamente.

## Artifacts temporários de credenciais

### `channel-rootfs-ssh-test-key`

Só é criado quando o modo escolhido realmente gera uma chave:

- `generated-key`;
- `generated-key+generated-password`.

Contém:

- `channel_test_ed25519`;
- `channel_test_ed25519.pub`.

Retenção: 1 dia.

### `channel-rootfs-ssh-password`

Só é criado quando o modo escolhido realmente gera uma senha:

- `generated-password`;
- `generated-key+generated-password`.

Contém:

- `channel_ssh_password.txt`.

Retenção: 1 dia.

Modos que usam Secrets ou uma chave pública fornecida pelo campo do Actions não exportam essas credenciais novamente.

## Execução automática por push

Pushes na branch `rootfs` também executam este workflow.

Nesse caso o modo é automático:

- se `SSH_PUBLIC_KEY` estiver configurado, ele é usado;
- se não estiver, a run gera uma chave Ed25519 e publica `channel-rootfs-ssh-test-key`.

## O que foi alterado nesta branch

A separação de `rootfs` manteve os scripts existentes e passou a publicar somente os resultados ligados ao rootfs.

Depois foram adicionados:

- seletor `ssh_auth` no disparo manual;
- campo `ssh_public_key` para fornecer uma chave pública diretamente no Actions;
- suporte aos Secrets `SSH_PUBLIC_KEY` e `SSH_PASSWORD`;
- geração opcional de senha;
- artifact temporário para senha gerada;
- combinações de chave + senha;
- opção `disabled`;
- registro do modo selecionado em `build-info.txt`.

O comportamento padrão continua usando chave gerada quando nenhuma configuração externa é fornecida.
