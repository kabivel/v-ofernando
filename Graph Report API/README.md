# 📊 Microsoft 365 Reports - Graph API

Sistema automatizado para extração de relatórios do Microsoft 365 via Microsoft Graph API.

---

## 🚀 Como Usar

Escolha uma das duas opções:

### **OPÇÃO 1: Login Interativo (Mais Fácil - Sem Setup)**

**Ideal para:** Uso único, testes, usuários finais

```powershell
cd "Graph Report API"
.\2_Graph_Only_Interactive.ps1
```

✅ Abre automaticamente um navegador para você fazer login  
✅ Sem necessidade de credenciais pré-configuradas  
✅ Perfeito para executar uma única vez  

**Pronto!** Os arquivos CSV serão salvos na pasta `Export\`

---

### **OPÇÃO 2: Com App Registration (Mais Profissional)**

**Ideal para:** Automação, agendamento, integração em sistemas

#### PASSO 1: Executar Setup
```powershell
cd "Graph Report API"
.\0_Setup_AppCretion.ps1
```

**O que acontece:**
- ✅ Instala módulos necessários
- ✅ Cria uma App Registration no Azure
- ✅ Configura permissões automaticamente
- ✅ Gera Client ID, Secret e Tenant ID

**Salve esses dados no próximo passo!**

#### PASSO 2: Configurar Credenciais

Abra o arquivo `2_Graph_Only.ps1` e substitua no início:

```powershell
$ClientId    = "VALOR_DO_SETUP"
$ClientSecret = "VALOR_DO_SETUP"
$TenantId    = "VALOR_DO_SETUP"
```

**Copie exatamente os valores que o Setup exibiu na tela.**

#### PASSO 3: Executar Extração
```powershell
.\2_Graph_Only.ps1
```

**Pronto!** Os arquivos CSV serão salvos na pasta `Export\`

---

## 📋 Relatórios Extraídos

| Categoria | Relatórios |
|----------|-----------|
| **Apps** | M365 App User Detail, Office 365 Activation Counts |
| **Exchange** | Email Activity, Mailbox Usage |
| **OneDrive** | OneDrive Usage, OneDrive Activity |
| **SharePoint** | SharePoint Activity, SharePoint Site Usage |
| **Teams** | Teams Device Usage, Teams Activity |
| **Copilot** | Copilot Interaction, Copilot Summary |

---

## ❓ Dúvidas Frequentes

### **P: Qual versão devo usar?**
**R:** 
- Use `2_Graph_Only_Interactive.ps1` se quer simplificar (login rápido)
- Use `2_Graph_Only.ps1` com setup se vai rodar repetidamente ou agendar

### **P: Na versão interativa, preciso fazer login toda vez?**
**R:** Não! Você faz login uma vez por sessão. A sessão mantém-se ativa até você fechar PowerShell.

### **P: E se quiser usar em tarefas agendadas (Scheduler)?**
**R:** Use a Opção 2 com App Registration - ela não requer interação do usuário.

### **P: Sempre preciso rodar o Setup?**
**R:** Não! Rode apenas uma vez. Depois use o `2_Graph_Only.ps1` quantas vezes quiser.

### **P: Onde estão os arquivos exportados?**
**R:** Na pasta `Export\` (criada automaticamente ao rodar o script).

### **P: Posso compartilhar o `graph_config.json`?**
**R:** Não! Contém credenciais sensíveis. Guarde com segurança.

### **P: O que significa "D90"?**
**R:** Dados dos últimos 90 dias (período padrão dos relatórios).

### **P: Meu relatório retornou erro/vazio**
**R:** Alguns relatórios podem não estar disponíveis para sua organização. Verifique se você tem as permissões e licenças necessárias.

---

## 🔒 Segurança

- ⚠️ **Nunca compartilhe** o Client Secret
- ⚠️ **Nunca commite** credenciais no Git
- ✅ Credentials são válidas por 1 ano (automaticamente renovável no Azure)

---

## 📁 Estrutura de Pastas

```
Graph Report API/
├── 0_Setup_AppCretion.ps1         ← [OPÇÃO 2] Execute primeiro
├── 2_Graph_Only.ps1               ← [OPÇÃO 2] Execute depois
├── 2_Graph_Only_Interactive.ps1   ← [OPÇÃO 1] Clique e pronto!
├── graph_config.json              ← Gerado automaticamente (OPÇÃO 2)
├── Export/                        ← Relatórios salvos aqui
│   ├── getM365AppUserDetail.csv
│   ├── getEmailActivityCounts.csv
│   └── ...
└── README.md                      ← Este arquivo
```

---

## 🆘 Ajuda

### **Para a versão Interativa:**
Se o navegador não abrir:
1. Copie o link que apareceu no PowerShell
2. Cole no seu navegador
3. Faça login e autorize o acesso
4. Volte ao PowerShell - deve continuar automaticamente

### **Para a versão com App Registration:**
Se receber erro:
1. Certifique-se que executou `0_Setup_AppCretion.ps1` primeiro
2. Copie as credenciais **exatamente** como exibidas
3. Verifique sua internet
4. Feche e reabra o PowerShell
5. Execute como Administrador se necessário

---

## 📞 Suporte

Para problemas específicos:
- **Erro de permissão**: Você pode precisar de acesso de Admin de Relatórios no M365
- **Relatórios vazios**: Dados podem não estar disponíveis para sua organização
- **Timeout**: Alguns relatórios podem levar mais tempo - aumente o timeout do PowerShell

---

**Versão:** 1.0 | **Último Update:** 09/03/2026
