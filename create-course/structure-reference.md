# Squelette structurel de la page de formation

Ce fichier décrit la structure technique attendue pour la page HTML générée. Il s'agit d'un squelette FONCTIONNEL à adapter, pas d'un design final : remplace les couleurs/typos par la direction visuelle choisie à l'étape 2 du SKILL.md, et adapte la structure (nombre de modules/leçons) au plan de l'étape 1.

## Squelette de base

```html
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><!-- Titre de la formation --></title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/styles/atom-one-dark.min.css">
<style>
  :root {
    /* Remplacer par la palette choisie à l'étape 2 */
    --bg: #ffffff;
    --bg-alt: #f5f5f5;
    --text: #1a1a1a;
    --text-muted: #6b6b6b;
    --accent: #2563eb;
    --border: #e5e5e5;

    --font-display: "Georgia", serif;     /* à remplacer */
    --font-body: system-ui, sans-serif;   /* à remplacer */

    --sidebar-width: 280px;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    font-family: var(--font-body);
    color: var(--text);
    background: var(--bg);
    line-height: 1.6;
  }

  .layout { display: flex; min-height: 100vh; }

  /* ---- Sidebar : navigation par module/leçon ---- */
  .sidebar {
    width: var(--sidebar-width);
    flex-shrink: 0;
    background: var(--bg-alt);
    border-right: 1px solid var(--border);
    padding: 1.5rem 1rem;
    overflow-y: auto;
    position: sticky;
    top: 0;
    height: 100vh;
  }

  .sidebar h1 {
    font-family: var(--font-display);
    font-size: 1.1rem;
    margin-bottom: 1rem;
  }

  .module-group { margin-bottom: 0.5rem; }

  .module-title {
    font-weight: 600;
    padding: 0.5rem 0.5rem;
    cursor: pointer;
    border-radius: 6px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .module-title:hover { background: var(--border); }

  .lesson-list { list-style: none; padding-left: 1rem; }
  .lesson-list li a {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.35rem 0.5rem;
    border-radius: 6px;
    color: var(--text-muted);
    text-decoration: none;
    font-size: 0.9rem;
  }
  .lesson-list li a:hover { background: var(--border); color: var(--text); }
  .lesson-list li a.active { color: var(--accent); font-weight: 600; }

  /* checkbox de progression, coché via JS + localStorage */
  .lesson-check {
    width: 14px; height: 14px; flex-shrink: 0;
    border: 1px solid var(--text-muted); border-radius: 3px;
  }
  .lesson-check.done { background: var(--accent); border-color: var(--accent); }

  /* ---- Barre de progression globale ---- */
  .progress-bar {
    height: 4px;
    background: var(--border);
    position: sticky; top: 0; z-index: 10;
  }
  .progress-bar-fill {
    height: 100%;
    background: var(--accent);
    width: 0%; /* mis à jour par JS */
    transition: width 0.2s ease;
  }

  /* ---- Contenu principal ---- */
  .content {
    flex: 1;
    max-width: 760px;
    margin: 0 auto;
    padding: 2rem;
  }

  .content h1 {
    font-family: var(--font-display);
    font-size: 2.2rem;
    margin-bottom: 0.5rem;
  }
  .content h2 {
    font-family: var(--font-display);
    font-size: 1.6rem;
    margin: 2.5rem 0 1rem;
    border-bottom: 1px solid var(--border);
    padding-bottom: 0.5rem;
  }
  .content h3 { margin: 1.5rem 0 0.5rem; }
  .content p, .content ul, .content ol { margin-bottom: 1rem; }

  pre {
    border-radius: 8px;
    padding: 1rem;
    overflow-x: auto;
    margin: 1rem 0;
  }

  /* Encadrés pièges / exercices */
  .callout {
    border-left: 4px solid var(--accent);
    background: var(--bg-alt);
    padding: 1rem;
    border-radius: 0 8px 8px 0;
    margin: 1rem 0;
  }
  .callout.pitfall { border-left-color: #e07a5f; }
  .callout.exercise { border-left-color: #43aa8b; }

  /* ---- Hamburger mobile ---- */
  .menu-toggle { display: none; }

  @media (max-width: 768px) {
    .sidebar {
      position: fixed;
      left: -100%;
      z-index: 20;
      transition: left 0.2s ease;
      box-shadow: 4px 0 12px rgba(0,0,0,0.1);
    }
    .sidebar.open { left: 0; }
    .menu-toggle {
      display: block;
      position: fixed;
      top: 1rem; left: 1rem;
      z-index: 30;
      background: var(--accent);
      color: white;
      border: none;
      border-radius: 6px;
      padding: 0.5rem 0.75rem;
      cursor: pointer;
    }
    .content { padding: 4rem 1.25rem 2rem; }
  }
</style>
</head>
<body>

<div class="progress-bar"><div class="progress-bar-fill" id="progressFill"></div></div>
<button class="menu-toggle" id="menuToggle">☰</button>

<div class="layout">
  <nav class="sidebar" id="sidebar">
    <h1><!-- Titre de la formation --></h1>

    <!-- Répéter ce bloc pour chaque module du plan (étape 1) -->
    <div class="module-group">
      <div class="module-title">Module 1 — <!-- titre du module --></div>
      <ul class="lesson-list">
        <li><a href="#m1-l1" data-lesson="m1-l1"><span class="lesson-check"></span> <!-- titre leçon 1 --></a></li>
        <li><a href="#m1-l2" data-lesson="m1-l2"><span class="lesson-check"></span> <!-- titre leçon 2 --></a></li>
      </ul>
    </div>
    <!-- fin du bloc à répéter -->

  </nav>

  <main class="content">

    <!-- Répéter ce bloc pour chaque leçon -->
    <section id="m1-l1">
      <h2><!-- Titre de la leçon --></h2>
      <p><!-- Explication du concept (pourquoi/comment) --></p>

      <pre><code class="language-python"><!-- exemple de code --></code></pre>

      <div class="callout pitfall">
        <strong>Piège courant</strong> — <!-- erreur fréquente --->
      </div>

      <div class="callout exercise">
        <strong>Exercice</strong> — <!-- question ou exercice -->
      </div>
    </section>
    <!-- fin du bloc à répéter -->

  </main>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
<script>
  hljs.highlightAll();

  // Toggle sidebar mobile
  const sidebar = document.getElementById('sidebar');
  document.getElementById('menuToggle').addEventListener('click', () => {
    sidebar.classList.toggle('open');
  });

  // Suivi de progression via localStorage : un check par leçon visitée
  const lessonLinks = document.querySelectorAll('[data-lesson]');
  const storageKey = 'course-progress-' + (document.title || 'default');
  const done = JSON.parse(localStorage.getItem(storageKey) || '{}');

  function updateProgressBar() {
    const total = lessonLinks.length;
    const completed = Object.values(done).filter(Boolean).length;
    document.getElementById('progressFill').style.width = (completed / total * 100) + '%';
  }

  lessonLinks.forEach(link => {
    const id = link.dataset.lesson;
    if (done[id]) link.querySelector('.lesson-check').classList.add('done');

    link.addEventListener('click', () => {
      done[id] = true;
      localStorage.setItem(storageKey, JSON.stringify(done));
      link.querySelector('.lesson-check').classList.add('done');
      updateProgressBar();
      // mobile : fermer la sidebar après clic
      sidebar.classList.remove('open');
    });
  });

  updateProgressBar();
</script>
</body>
</html>
```

## Points à respecter en l'adaptant

- **Une seule page, plusieurs `<section>`** : chaque leçon est une `<section id="...">` ciblée par un lien de la sidebar (ancre `#id`). Pas de rechargement de page.
- **Couleurs et polices** : remplacer toutes les variables CSS du `:root` par la direction visuelle de l'étape 2 — ne pas garder le bleu/gris par défaut de ce squelette.
- **`language-xxx`** dans les balises `<code>` : adapter au langage réellement utilisé dans chaque exemple (`language-python`, `language-javascript`, `language-bash`, etc.) pour que la coloration syntaxique fonctionne.
- **localStorage** : fonctionne uniquement parce que c'est un fichier HTML autonome ouvert directement dans le navigateur (pas un artifact claude.ai, où localStorage est interdit). Si jamais ce squelette est adapté pour un artifact React/HTML dans Claude.ai, remplacer par un state en mémoire.
- Si la formation est scindée en plusieurs fichiers (cas des très gros sujets, voir étape 6 du SKILL.md), dupliquer la sidebar dans chaque fichier et faire pointer les liens de modules vers `module-N.html#l1` plutôt que `#m1-l1`.
