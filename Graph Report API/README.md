# 📊 Microsoft 365 Reports - Graph API

Sistema automatizado para extração de relatórios do Microsoft 365 via Microsoft Graph API.

---

## 🚀 Como Usar (3 passos)

### **PASSO 1: Executar Setup**
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

---

### **PASSO 2: Configurar Credenciais**

Abra o arquivo `2_Graph_Only.ps1` e substitua no início:

```powershell
$ClientId    = "VALOR_DO_SETUP"
$ClientSecret = "VALOR_DO_SETUP"
$TenantId    = "VALOR_DO_SETUP"
```

**Copie exatamente os valores que o Setup exibiu na tela.**

---

### **PASSO 3: Executar Extração**
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

### **P: Sempre preciso rodar o Setup?**
**R:** Não! Rode apenas uma vez. Depois use o `2_Graph_Only.ps1` quantas vezes quiser.

### **P: Onde estão os arquivos exportados?**
**R:** Na pasta `Export\` (criada automaticamente ao rodar o script).

### **P: Posso compartilhar o `graph_config.json`?**
**R:** Não! Contém credenciais sensíveis. Guarde com segurança.

### **P: O que significa "D90"?**
**R:** Dados dos últimos 90 dias (período padrão dos relatórios).

---

## 🔒 Segurança

- ⚠️ **Nunca compartilhe** o Client Secret
- ⚠️ **Nunca commite** credenciais no Git
- ✅ Credentials são válidas por 1 ano (automaticamente renovável no Azure)

---

## 📁 Estrutura de Pastas

```
Graph Report API/
├── 0_Setup_AppCretion.ps1    ← Execute primeiro
├── 2_Graph_Only.ps1          ← Execute depois
├── graph_config.json          ← Gerado automaticamente
├── Export/                    ← Relatórios salvos aqui
│   ├── getM365AppUserDetail.csv
│   ├── getEmailActivityCounts.csv
│   └── ...
└── README.md                  ← Este arquivo
```

---

## 🆘 Ajuda

Se receber erro:
1. Certifique-se que executou `0_Setup_AppCretion.ps1` primeiro
2. Copie as credenciais **exatamente** como exibidas
3. Verifique sua internet
4. Feche e reabra o PowerShell
5. Execute como Administrador

---

**Versão:** 1.0 | **Último Update:** 09/03/2026
