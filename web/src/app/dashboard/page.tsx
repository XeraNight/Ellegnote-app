import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import DashboardClient from './DashboardClient'

export default async function DashboardPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  // Middleware handles redirect but double-check server-side (defense in depth)
  if (!user) redirect('/login')

  // Fetch routines
  const { data: routines } = await supabase
    .from('routines')
    .select('*')
    .order('updated_at', { ascending: false })

  // Fetch figures
  const { data: figures } = await supabase
    .from('figure_library_items')
    .select('*')
    .order('name', { ascending: true })

  return (
    <DashboardClient
      user={{ email: user.email ?? '', id: user.id }}
      routines={routines ?? []}
      figures={figures ?? []}
    />
  )
}
