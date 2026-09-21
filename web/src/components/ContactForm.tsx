'use client'

import { useForm, ValidationError } from '@formspree/react'

export function ContactForm() {
  const [state, handleSubmit] = useForm('myeyrbza')

  if (state.succeeded) {
    return (
      <div className="flex flex-col items-center justify-center gap-4 py-12 text-center">
        <div className="text-4xl">✉️</div>
        <h3 className="text-xl font-serif font-bold text-white">
          Správa odoslaná!
        </h3>
        <p className="text-sm text-zinc-400 max-w-xs">
          Ďakujeme za Vašu správu. Odpovieme do 48 hodín na Váš email.
        </p>
      </div>
    )
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      {/* Name + Email row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="space-y-1.5">
          <label htmlFor="name" className="block text-xs font-semibold uppercase tracking-wider text-zinc-400">
            Meno
          </label>
          <input
            id="name"
            type="text"
            name="name"
            required
            placeholder="Vaše meno"
            className="w-full bg-[#0D0C13] border border-zinc-800 rounded-xl px-4 py-3 text-sm text-white placeholder-zinc-600 focus:outline-none focus:border-[#D4AF37]/60 focus:ring-1 focus:ring-[#D4AF37]/30 transition"
          />
          <ValidationError field="name" prefix="Meno" errors={state.errors} className="text-xs text-red-400 mt-1" />
        </div>

        <div className="space-y-1.5">
          <label htmlFor="email" className="block text-xs font-semibold uppercase tracking-wider text-zinc-400">
            Email
          </label>
          <input
            id="email"
            type="email"
            name="email"
            required
            placeholder="vas@email.sk"
            className="w-full bg-[#0D0C13] border border-zinc-800 rounded-xl px-4 py-3 text-sm text-white placeholder-zinc-600 focus:outline-none focus:border-[#D4AF37]/60 focus:ring-1 focus:ring-[#D4AF37]/30 transition"
          />
          <ValidationError field="email" prefix="Email" errors={state.errors} className="text-xs text-red-400 mt-1" />
        </div>
      </div>

      {/* Category */}
      <div className="space-y-1.5">
        <label htmlFor="category" className="block text-xs font-semibold uppercase tracking-wider text-zinc-400">
          Kategória
        </label>
        <select
          id="category"
          name="category"
          className="w-full bg-[#0D0C13] border border-zinc-800 rounded-xl px-4 py-3 text-sm text-white focus:outline-none focus:border-[#D4AF37]/60 focus:ring-1 focus:ring-[#D4AF37]/30 transition appearance-none"
        >
          <option value="bug">🐛 Nahlásenie chyby (Bug)</option>
          <option value="feature">💡 Návrh novej funkcie</option>
          <option value="account">👤 Otázka k účtu alebo dátam</option>
          <option value="other">📬 Iné</option>
        </select>
        <ValidationError field="category" prefix="Kategória" errors={state.errors} className="text-xs text-red-400 mt-1" />
      </div>

      {/* Message */}
      <div className="space-y-1.5">
        <label htmlFor="message" className="block text-xs font-semibold uppercase tracking-wider text-zinc-400">
          Správa
        </label>
        <textarea
          id="message"
          name="message"
          required
          rows={5}
          placeholder="Opíšte Váš problém alebo návrh čo najpresnejšie..."
          className="w-full bg-[#0D0C13] border border-zinc-800 rounded-xl px-4 py-3 text-sm text-white placeholder-zinc-600 focus:outline-none focus:border-[#D4AF37]/60 focus:ring-1 focus:ring-[#D4AF37]/30 transition resize-none"
        />
        <ValidationError field="message" prefix="Správa" errors={state.errors} className="text-xs text-red-400 mt-1" />
      </div>

      {/* General form error */}
      {state.errors && (
        <ValidationError errors={state.errors} className="text-xs text-red-400" />
      )}

      <button
        type="submit"
        disabled={state.submitting}
        className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-8 py-3 rounded-xl bg-gradient-to-r from-[#F5D77F] via-[#D4AF37] to-[#AA7C11] text-[#060608] font-bold text-sm hover:opacity-95 active:scale-[0.98] transition shadow-lg shadow-[#D4AF37]/20 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {state.submitting ? 'Odosielam…' : 'Odoslať správu ✉️'}
      </button>
    </form>
  )
}
