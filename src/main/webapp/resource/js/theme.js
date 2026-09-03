// 페이지 로드 시 저장된 테마를 즉시 적용 (FOUC 방지를 위해 <head>에서 동기 실행)
(function () {
    var saved = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-theme', saved);
})();

function updateThemeIcon(theme) {
    var btn = document.getElementById('themeToggleBtn');
    if (!btn) return;
    btn.textContent = theme === 'dark' ? '☀️' : '🌙';
}

function toggleTheme() {
    var current = document.documentElement.getAttribute('data-theme');
    var next = current === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('theme', next);
    updateThemeIcon(next);
}

document.addEventListener('DOMContentLoaded', function () {
    updateThemeIcon(document.documentElement.getAttribute('data-theme') || 'light');
});
