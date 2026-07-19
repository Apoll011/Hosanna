# Protocolo de Sincronização Remota (API de Cifras & Cultos)

Este documento descreve as especificações técnicas, formatos de dados e endpoints necessários para implementar o servidor de sincronização remota para a aplicação de Cifras e Cultos.

A arquitetura do sistema utiliza uma abordagem de sincronização transacional para manter arquivos virtuais (cifras no formato ChordPro) e listas de cultos planeados em harmonia entre múltiplos dispositivos e o servidor central.

---

## 1. Configuração da Conexão

Na secção de **Ajustes** da aplicação, o utilizador pode configurar:
1. **URL do Servidor Remoto**: O endereço base da API (ex: `https://api.cifras.exemplo.com`).
2. **Token de Segurança (Bearer Token)**: Chave opcional enviada no cabeçalho de autenticação.

Quando a URL do servidor está preenchida, todas as ações de sincronização efetuam pedidos HTTPS automáticos.

---

## 2. Autenticação

Todos os pedidos enviados ao servidor incluem cabeçalhos de segurança caso o Token esteja configurado na aplicação:

```http
Authorization: Bearer <token_de_seguranca_configurado>
Content-Type: application/json
```

---

## 3. Endpoint Principal de Sincronização: `POST /api/sync`

Este endpoint processa o intercâmbio bidirecional das cifras virtuais e do planeamento de cultos em lote.

### 3.1. Payload do Pedido (Request Body)

A aplicação envia o estado dos seus ficheiros e cultos locais acompanhados da data de modificação (`updatedAt`):

```json
{
  "files": [
    {
      "path": "Adoração/Digno_és_Tu.chopro",
      "updatedAt": 1721382400000
    },
    {
      "path": "Geral/Grande_é_o_Senhor.chopro",
      "updatedAt": 1721382450000
    }
  ],
  "services": [
    {
      "id": "service-1721382400000",
      "name": "Culto de Domingo de Manhã",
      "date": "2026-07-19",
      "songIds": [
        "Adoração/Digno_és_Tu.chopro",
        "Geral/Grande_é_o_Senhor.chopro"
      ],
      "notes": "Preparar pregação antes do cântico...",
      "songNotes": {
        "0": "Aline Barros guia o refrão repetidamente."
      }
    }
  ]
}
```

### 3.2. Formato da Resposta do Servidor (Response Body)

O servidor deve processar os ficheiros e cultos locais (adicionando ficheiros novos, comparando timestamps ou aplicando uma política de *Source of Truth* centralizada) e responder com a lista final consolidada:

```json
{
  "files": [
    {
      "path": "Adoração/Digno_és_Tu.chopro",
      "content": "{title: Digno és Tu}\n{artist: Aline Barros}\n...\n",
      "updatedAt": 1721382400000
    },
    {
      "path": "Geral/Grande_é_o_Senhor.chopro",
      "content": "{title: Grande é o Senhor}\n...\n",
      "updatedAt": 1721382450000
    }
  ],
  "services": [
    {
      "id": "service-1721382400000",
      "name": "Culto de Domingo de Manhã",
      "date": "2026-07-19",
      "songIds": [
        "Adoração/Digno_és_Tu.chopro",
        "Geral/Grande_é_o_Senhor.chopro"
      ],
      "notes": "Preparar pregação antes do cântico...",
      "songNotes": {
        "0": "Aline Barros guia o refrão repetidamente."
      }
    }
  ]
}
```

---

## 4. Exemplo Prático de Servidor (Node.js + Express)

Abaixo encontra-se uma implementação de referência em Node.js com Express para servir de ponto de partida:

```javascript
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 4000;
const SECURITY_TOKEN = 'meu_token_secreto_da_igreja';

// Base de dados simulada (Em produção, ligue à sua base SQL/MongoDB)
let serverFiles = [
  {
    path: 'Adoração/Digno_és_Tu.chopro',
    content: '{title: Digno és Tu}\n{artist: Aline Barros}\n{key: E}\n\n{soc}\n[E]Digno és [A]Tu de glória...\n{eoc}',
    updatedAt: 1721382400000
  },
  {
    path: 'Geral/Grande_é_o_Senhor.chopro',
    content: '{title: Grande é o Senhor}\n{key: G}\n\n{soc}\n[G]Grande é o Se[C]nhor e mui digno...\n{eoc}',
    updatedAt: 1721382450000
  }
];

let serverServices = [
  {
    id: 'service-demo',
    name: 'Culto de Domingo de Manhã',
    date: '2026-07-19',
    songIds: ['Adoração/Digno_és_Tu.chopro', 'Geral/Grande_é_o_Senhor.chopro'],
    notes: 'Preparar pregação antes do cântico de transição.',
    songNotes: { '0': 'Aline Barros guia o refrão repetidamente.' }
  }
];

// Middleware de Autenticação
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token de segurança ausente ou inválido.' });
  }
  const token = authHeader.split(' ')[1];
  if (token !== SECURITY_TOKEN) {
    return res.status(403).json({ error: 'Acesso negado. Token incorreto.' });
  }
  next();
}

// Endpoint de Sincronização
app.post('/api/sync', authenticate, (req, res) => {
  const { files: clientFiles, services: clientServices } = req.body;

  // Política Simples: Servidor é a Fonte de Verdade para ficheiros virtuais, 
  // mas permite atualizações de cultos enviadas pelo cliente.
  
  if (clientServices && Array.isArray(clientServices)) {
    // Mesclar cultos recebidos (substituir se mais recentes ou adicionar novos)
    clientServices.forEach(clientSvc => {
      const idx = serverServices.findIndex(s => s.id === clientSvc.id);
      if (idx !== -1) {
        serverServices[idx] = clientSvc; // Overwrite
      } else {
        serverServices.push(clientSvc); // Add new
      }
    });
  }

  // Responder com a biblioteca consolidada
  res.json({
    files: serverFiles,
    services: serverServices
  });
});

app.listen(PORT, () => {
  console.log(`Servidor de Cifras a correr em http://localhost:${PORT}`);
});
```

---

## 5. Resolução de Erros

A aplicação lida autonomamente com os seguintes códigos de resposta do servidor:

- **`401 Unauthorized` / `403 Forbidden`**: A aplicação reporta erro de credenciais ou token inválido na barra de sincronização.
- **`500 Internal Server Error` / Erro de Rede**: A aplicação volta ao estado offline seguro, mantendo a cache local intacta e utilizável sem qualquer perda de dados.
