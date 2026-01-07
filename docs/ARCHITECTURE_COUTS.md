# 🔌 ARCHITECTURE BACKEND & COÛTS - Horse Tempo

## 📊 SOURCES DE DONNÉES ÉQUINES

### 1. SIRE/IFCE (France) - Base Officielle
**URL:** https://infochevaux.ifce.fr/fr/info-chevaux

| Accès | Coût | Contenu |
|-------|------|---------|
| Info Chevaux (web) | **GRATUIT** | Consultation publique |
| API officielle | **Sur devis** | Contact SIRE nécessaire |
| Extraction données | ~500-2000€/an | Convention à négocier |

**Données disponibles:**
- UELN (identifiant unique)
- Généalogie (père, mère, grands-parents)
- Race, robe, sexe, date de naissance
- Propriétaire actuel
- Indices génétiques (ISO, IDR, ICC)

**Contact:** 0 809 10 01 01 (matin 9h-12h)

---

### 2. FEI Database (International)
**URL:** https://data.fei.org/

| Accès | Coût | Contenu |
|-------|------|---------|
| Consultation | **GRATUIT** | Via fédération nationale |
| API commerciale | **Sur devis** | Contact FEI |

**Données:** 493,559 chevaux, résultats compétitions internationales

---

### 3. Weatherbys (UK - Pur-sang)
**URL:** https://www.weatherbys.co.uk/commercial/data-supply

| Service | Coût estimé |
|---------|-------------|
| Stallion Data API | £2,000-10,000/an |
| Full pedigree feed | £5,000-20,000/an |
| Bespoke data | Sur devis |

**Plus grande base européenne de pur-sang**

---

### 4. SporthorseData
**URL:** https://sporthorse-data.com/

| Accès | Coût |
|-------|------|
| Basique | **GRATUIT** |
| Pro | ~100-300€/an |

**Pedigrees et résultats chevaux de sport**

---

### 5. WBFSH (World Breeding Federation)
**URL:** https://prod.wbfsh.com/

En partenariat avec **Equine Register** - Base centralisée en développement

---

## 🤖 COÛTS ANALYSE IA (par analyse vidéo)

### OpenAI GPT-4o Vision
| Détail | Coût |
|--------|------|
| Input | $2.50-5.00 / 1M tokens |
| Output | $10.00-15.00 / 1M tokens |
| Image basse résolution | ~$0.003 / image |
| Image haute résolution | ~$0.01-0.03 / image |

**Pour une vidéo de 30 secondes (30 frames):**
- Basse résolution: ~$0.10-0.15
- Haute résolution: ~$0.50-1.00

### Anthropic Claude (Vision)
| Modèle | Input | Output |
|--------|-------|--------|
| Claude 3 Haiku | $0.25/1M | $1.25/1M |
| Claude 3 Sonnet | $3.00/1M | $15.00/1M |
| Claude 3 Opus | $15.00/1M | $75.00/1M |

### Google Gemini
| Modèle | Input | Output |
|--------|-------|--------|
| Gemini 1.5 Flash | $0.075/1M | $0.30/1M |
| Gemini 1.5 Pro | $1.25/1M | $5.00/1M |

---

## 💰 ESTIMATION COÛTS MENSUELS

### Scénario: 1000 utilisateurs actifs

| Poste | Coût/mois |
|-------|-----------|
| **Hébergement** | |
| VPS (API + DB) | 50-100€ |
| Stockage vidéos (S3) | 100-300€ |
| CDN | 50-100€ |
| **APIs Externes** | |
| SIRE (si convention) | ~150€ |
| OpenAI/Claude (analyses) | 200-500€ |
| **Infrastructure** | |
| Firebase/Auth | 50€ |
| Notifications push | 20€ |
| SMS (OTP) | 30-50€ |
| **TOTAL** | **~650-1200€/mois** |

### Scénario: 10,000 utilisateurs actifs

| Poste | Coût/mois |
|-------|-----------|
| Hébergement | 300-500€ |
| Stockage | 500-1000€ |
| CDN | 200-400€ |
| APIs équines | 500-1000€ |
| IA (analyses) | 1000-3000€ |
| Autres | 300-500€ |
| **TOTAL** | **~3000-6500€/mois** |

---

## 🔧 ARCHITECTURE TECHNIQUE PROPOSÉE

```
┌─────────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    API GATEWAY (NestJS)                      │
│  - Authentication (JWT)                                      │
│  - Rate Limiting                                             │
│  - Request Validation                                        │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  CORE API     │   │  AI SERVICE   │   │  DATA SERVICE │
│  (NestJS)     │   │  (Python)     │   │  (NestJS)     │
│               │   │               │   │               │
│ - Users       │   │ - Video       │   │ - SIRE Sync   │
│ - Horses      │   │   Analysis    │   │ - FEI Sync    │
│ - Analyses    │   │ - Character   │   │ - Argus Calc  │
│ - Reports     │   │   Detection   │   │ - Histovec    │
│ - Marketplace │   │ - Locomotion  │   │               │
└───────────────┘   └───────────────┘   └───────────────┘
        │                   │                   │
        └───────────────────┼───────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      BASE DE DONNÉES                         │
│                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │  PostgreSQL │  │    Redis    │  │ Elasticsearch│         │
│  │  (Main DB)  │  │   (Cache)   │  │  (Search)   │         │
│  └─────────────┘  └─────────────┘  └─────────────┘         │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│  AWS S3       │   │  OpenAI API   │   │  SIRE/IFCE    │
│  (Stockage)   │   │  Claude API   │   │  FEI API      │
└───────────────┘   └───────────────┘   └───────────────┘
```

---

## 📋 APIs À DÉVELOPPER

### 1. Service Synchronisation SIRE
```typescript
// Scraping ou API officielle
interface SireService {
  searchHorse(ueln: string): Promise<SireHorse>;
  getIndices(horseId: string): Promise<GeneticIndices>;
  getPedigree(horseId: string, depth: number): Promise<Pedigree>;
}
```

### 2. Service Analyse IA
```typescript
interface AIAnalysisService {
  analyzeVideo(videoUrl: string): Promise<VideoAnalysis>;
  detectCharacter(frames: Frame[]): Promise<CharacterProfile>;
  analyzeLocomotion(frames: Frame[]): Promise<LocomotionProfile>;
  analyzeConformation(images: Image[]): Promise<ConformationProfile>;
}
```

### 3. Service Argus
```typescript
interface ArgusService {
  calculateValuation(horseId: string): Promise<HorseArgus>;
  getMarketComparables(criteria: SearchCriteria): Promise<Comparable[]>;
  getMarketTrend(breed: string, discipline: string): Promise<Trend>;
}
```

### 4. Service Histovec
```typescript
interface HistovecService {
  generateReport(horseId: string): Promise<HorseHistovec>;
  verifyOwnership(ueln: string): Promise<OwnershipVerification>;
  getVetHistory(horseId: string): Promise<VetRecord[]>;
}
```

---

## 💡 ALTERNATIVES LOW-COST

### Option 1: Scraping Info Chevaux (GRATUIT mais risqué)
- Scraper https://infochevaux.ifce.fr
- ⚠️ Risque de blocage IP
- ⚠️ Légalité discutable

### Option 2: Données contributives
- Les utilisateurs renseignent leurs chevaux
- Vérification par document (passeport)
- Base enrichie progressivement

### Option 3: Partenariat IFCE
- Convention de partenariat officielle
- Accès API négocié
- ~2000-5000€/an probablement

### Option 4: Modèle IA local
- Llama 3.2 Vision (gratuit, self-hosted)
- Coût serveur GPU: ~200-500€/mois
- Qualité légèrement inférieure

---

## 📈 MODÈLE DE RENTABILITÉ

### Revenus possibles
| Source | Prix | Marge |
|--------|------|-------|
| Abonnement Pro | 29€/mois | ~25€ |
| Analyse unique | 5€ | ~3€ |
| Annonce Marketplace | 15€ | ~14€ |
| Annonce Premium | 50€ | ~48€ |
| Argus/Histovec | 25€ | ~20€ |

### Break-even
- **1000 abonnés Pro** = 25,000€/mois de marge
- Coûts ~3000€ = **Rentable à ~150 abonnés Pro**

---

## 🚀 ROADMAP TECHNIQUE

### Phase 1 (MVP) - 2 mois
- [ ] API Core fonctionnelle
- [ ] Analyse IA basique (OpenAI)
- [ ] Données saisies manuellement
- [ ] Coût: ~1000€/mois

### Phase 2 (Beta) - 2 mois
- [ ] Intégration SIRE (scraping ou convention)
- [ ] Argus V1 (algorithme basique)
- [ ] Marketplace fonctionnel
- [ ] Coût: ~2000€/mois

### Phase 3 (Production) - 3 mois
- [ ] IA avancée (caractère, locomotion)
- [ ] Histovec complet
- [ ] Matching élevage IA
- [ ] Coût: ~4000€/mois

---

## 📞 CONTACTS UTILES

| Organisation | Contact |
|--------------|---------|
| SIRE/IFCE | 0 809 10 01 01 |
| FFE (compétitions) | federation@ffe.com |
| ANSF (Selle Français) | contact@sellefrancais.fr |
| SHF (élevage sport) | info@shf.eu |

---

*Document généré pour Horse Tempo - Janvier 2025*
