export default function Home() {
  return (
    <main className="mx-auto flex min-h-screen max-w-2xl flex-col justify-center gap-4 px-6 py-16">
      <h1 className="text-2xl font-semibold">Petitie-app — stap 1</h1>
      <p className="text-gray-700">
        De basis van het project draait. Hierna bouwen we in stappen: het
        ondertekenformulier, de bevestigingsmail, de publieke lijst met
        handtekeningen, de verwijderflow en de beheerpagina.
      </p>
      <p className="text-sm text-gray-500">
        Als je deze tekst op de preview-link ziet, werkt de eerste stap.
      </p>
    </main>
  );
}
