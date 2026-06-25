export default function Home() {
  return (
    <main className="min-h-screen p-8">
      <h1 className="text-2xl font-bold mb-4">RIAD Smart System</h1>
      <nav className="space-y-2">
        <a href="/calculator" className="block text-blue-400 hover:underline">Калькулятор</a>
        <a href="/estimates/new" className="block text-blue-400 hover:underline">Кошториси</a>
        <a href="/admin/scenarios" className="block text-blue-400 hover:underline">Сценарії</a>
        <a href="/warehouse" className="block text-blue-400 hover:underline">Склад</a>
      </nav>
    </main>
  )
}
