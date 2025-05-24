import { readable } from 'svelte/store';

export const colors = readable({
  light: {
    navbar: '#EFE9FF',
    bgColor: '#FAF8FF',
    bgLightColor: '#FFFFFF',
    surface: '#F5F3FF',
    cardBg: '#FFFFFF',

    color: '#1C143D',               // Main text
    colorMuted: '#6B7280',          // Tailwind gray-500
    headingColor: '#111827',        // Tailwind gray-900

    btn: '#8C6AED',                 // Primary button
    btnHover: '#7A57DF',
    btnText: '#FFFFFF',
    btnSecondary: '#E5E7EB',        // Tailwind gray-200

    inputBg: '#FFFFFF',
    inputBorder: '#D1D5DB',         // Tailwind gray-300
    inputFocus: '#8C6AED',

    borderColor: '#E5E7EB',
    accent: '#8C6AED',

    shadowLight: '0 1px 3px rgba(0, 0, 0, 0.08)',
    shadowDark: '0 4px 12px rgba(140, 106, 237, 0.3)',
  },

  dark: {
    navbar: '#1C143D',
    bgColor: '#110A2A',
    bgLightColor: '#1C143D',
    surface: '#1A112D',
    cardBg: '#1E1834',

    color: '#F7FAFC',               // Main text
    colorMuted: '#A0AEC0',          // Tailwind gray-400
    headingColor: '#EDE9FE',        // Tailwind violet-100

    btn: '#8C6AED',                 // Primary button
    btnHover: '#A78BFA',
    btnText: '#FFFFFF',
    btnSecondary: '#2D2E3A',

    inputBg: '#2A2045',
    inputBorder: '#4B445C',
    inputFocus: '#C4B5FD',          // Lighter violet

    borderColor: '#3F3B53',
    accent: '#C084FC',

    shadowLight: '0 1px 3px rgba(255, 255, 255, 0.05)',
    shadowDark: '0 4px 12px rgba(140, 106, 237, 0.3)',
  }
});
