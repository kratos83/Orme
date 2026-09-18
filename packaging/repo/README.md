# Repository apt/rpm di Orme

Ad ogni tag `v*`, dopo che `linux-packages.yml` ha compilato i pacchetti,
il job `publish-repo` genera un repository **apt** (Debian/Ubuntu) e tre
repository **rpm** (Fedora, openSUSE, Mageia), li firma con la chiave GPG
del progetto e li pubblica su GitHub Pages:

- apt: `https://kratos83.github.io/Orme/apt`
- rpm: `https://kratos83.github.io/Orme/rpm/{fedora,opensuse,mageia}`

Il pacchetto `.deb`/`.rpm` stesso installa il file che abilita il proprio
repository (`/etc/apt/sources.list.d/orme.list` per Debian,
`/etc/yum.repos.d/orme.repo` o `/etc/zypp/repos.d/orme.repo` per le rpm) e
importa la chiave pubblica, cosi' le versioni successive arrivano con i
normali `apt upgrade` / `dnf update` / `zypper update` del sistema, senza
bisogno di riscaricare nulla a mano da GitHub Releases.

Arch e Alpine restano **esclusi** (scelta esplicita): continuano ad avere
solo il pacchetto scaricabile dalle Release, nessun repository personale.

## File di questa cartella

- `orme.list` - sorgente apt (installato da `debian/orme.install`)
- `orme-archive-keyring.gpg` / `.asc` - chiave pubblica del progetto, forma
  binaria (per `signed-by=` di apt) e ASCII-armored (per `gpgkey=` rpm e
  per la pagina di download)
- `orme-fedora.repo`, `orme-opensuse.repo`, `orme-mageia.repo` - sorgenti
  rpm, uno per distro (installati dai rispettivi `.spec`)

## Impostazione una tantum (solo per chi amministra il repository GitHub)

Il job CI non puo' fare queste due cose da solo, vanno fatte una volta sola
dall'interfaccia web di GitHub:

1. **Abilitare Pages**: Settings → Pages → Build and deployment → Source:
   "GitHub Actions" (senza questo, `actions/deploy-pages` fallisce).
2. **Aggiungere il secret della chiave privata**: Settings → Secrets and
   variables → Actions → "New repository secret", nome
   `ORME_GPG_PRIVATE_KEY`, valore = la chiave privata ASCII-armored.

## La chiave GPG

E' stata generata (RSA 4096, nessuna scadenza, **senza passphrase** - la
CI deve poter firmare senza interazione; la protezione della chiave e'
il fatto stesso di essere un secret della CI, mai committata) con:

```bash
gpg --quick-generate-key "Orme Release Signing Key <angelo.scarna@primanotanet.it>" rsa4096 sign never
```

Fingerprint: `709EBF1F8F411B753567943BCC59C21D984337E0`

La chiave pubblica e' in questa cartella (committata, e' pubblica per
definizione). **La chiave privata non e' mai stata committata**: e' stata
esportata solo su questa macchina, per essere incollata nel secret
`ORME_GPG_PRIVATE_KEY` (punto 2 sopra) ed eliminata subito dopo. Se va persa
o compromessa, se ne genera una nuova con lo stesso comando, si sostituisce
`orme-archive-keyring.gpg`/`.asc` in questa cartella, il `%post`/`signed-by=`
nei pacchetti punta gia' ai nomi file giusti quindi basta ripubblicare una
nuova versione con la chiave nuova - gli utenti dovranno pero' reimportare
la chiave a mano una volta (`rpm --import` / rifare `apt install` del .deb)
perche' il vecchio pacchetto ha fidato solo la vecchia chiave.
