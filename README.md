# Linx Nightscout Bridge

MVP iPhone app pentru fluxul:

```text
Linx -> Apple Health -> LinxNightscoutBridge -> Nightscout
```

Aplicația citește ultima valoare `Blood Glucose` din Apple Health și o trimite către Nightscout prin `/api/v1/entries.json`.

## Ce face acum

- cere permisiune HealthKit pentru citirea glicemiei;
- citește cea mai recentă valoare din ultimele 24h;
- trimite valoarea în Nightscout ca `sgv`;
- evită upload-ul duplicat pentru același sample HealthKit;
- include pregătire minimă pentru background refresh, dar sync-ul principal este manual/la deschiderea aplicației.

## Ce trebuie modificat înainte de build real pe iPhone

În `project.yml` schimbă:

```yaml
DEVELOPMENT_TEAM: YOUR_TEAM_ID
```

cu Team ID-ul tău Apple Developer.

Exemplu:

```yaml
DEVELOPMENT_TEAM: ABC123DEFG
```

Bundle ID-ul implicit este:

```text
ro.heygluco.LinxNightscoutBridge
```

Poți să-l schimbi, dar trebuie să fie același în Apple Developer.

## Build local sau GitHub

Proiectul folosește XcodeGen, ca să nu ținem manual fișierul `.xcodeproj` în repo.

Local:

```bash
brew install xcodegen
xcodegen generate
open LinxNightscoutBridge.xcodeproj
```

GitHub Actions:

- workflow-ul inclus face un build de verificare pe simulator;
- pentru IPA semnat, trebuie adăugate certificate/provisioning profile ca secrets, exact cum faci la Trio/Loop.

## Setări în aplicație

În aplicație introduci:

- Nightscout URL, de forma `https://siteul-tau.ro` fără `/api/v1`;
- API_SECRET normal, nehashuit. Aplicația îl convertește SHA1 automat pentru header-ul Nightscout.

## Limitări MVP

- iOS nu garantează sync în fundal la interval fix;
- aplicația nu citește direct din Linx, ci doar din Apple Health;
- direcția este trimisă momentan ca `Flat`, pentru că Apple Health poate să nu ofere trend CGM;
- nu trimite încă istoric, doar ultima valoare.

## Următorii pași

1. Verifici în Apple Health că Linx scrie valori la `Blood Glucose`.
2. Creezi repo GitHub și urci aceste fișiere.
3. Schimbi `DEVELOPMENT_TEAM`.
4. Rulezi workflow-ul.
5. După ce build-ul simplu trece, adăugăm semnarea IPA.
