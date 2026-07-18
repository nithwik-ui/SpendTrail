---
name: Serene Financial
colors:
  surface: '#f7fafb'
  surface-dim: '#d7dadb'
  surface-bright: '#f7fafb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f4f5'
  surface-container: '#ebeeef'
  surface-container-high: '#e6e9ea'
  surface-container-highest: '#e0e3e4'
  on-surface: '#181c1d'
  on-surface-variant: '#3e494a'
  inverse-surface: '#2d3132'
  inverse-on-surface: '#eef1f2'
  outline: '#6f797a'
  outline-variant: '#bec8ca'
  surface-tint: '#006972'
  primary: '#00535b'
  on-primary: '#ffffff'
  primary-container: '#006d77'
  on-primary-container: '#9becf7'
  inverse-primary: '#82d3de'
  secondary: '#236863'
  on-secondary: '#ffffff'
  secondary-container: '#a9ece5'
  on-secondary-container: '#286d67'
  tertiary: '#713d10'
  on-tertiary: '#ffffff'
  tertiary-container: '#8e5426'
  on-tertiary-container: '#ffd7bd'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#9ff0fb'
  primary-fixed-dim: '#82d3de'
  on-primary-fixed: '#001f23'
  on-primary-fixed-variant: '#004f56'
  secondary-fixed: '#acefe7'
  secondary-fixed-dim: '#90d3cb'
  on-secondary-fixed: '#00201e'
  on-secondary-fixed-variant: '#00504b'
  tertiary-fixed: '#ffdcc5'
  tertiary-fixed-dim: '#ffb783'
  on-tertiary-fixed: '#301400'
  on-tertiary-fixed-variant: '#6d390c'
  background: '#f7fafb'
  on-background: '#181c1d'
  surface-variant: '#e0e3e4'
typography:
  display:
    fontFamily: Inter
    fontSize: 44px
    fontWeight: '600'
    lineHeight: 52px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  title-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  container-padding: 24px
  gutter: 16px
  section-gap: 40px
  max-width-desktop: 1200px
---

## Brand & Style
The design system is built on the principle of "Quiet Utility." It targets individuals seeking a mindful approach to financial tracking, removing the anxiety often associated with budgeting through a calm, distraction-free interface. 

The style is a **Bespoke Minimalist** evolution of Material 3. It retains the functional logic of M3 but replaces its generic "out-of-the-box" feel with a more intentional, editorial aesthetic. The UI relies on generous whitespace, high-quality typography, and a reduced cognitive load. Visual interest is generated through precise alignment and subtle tonal shifts rather than decorative elements.

## Colors
The palette is rooted in a "paper and ink" philosophy to promote legibility and a sense of permanence.

- **Primary (Deep Teal):** Used sparingly for primary actions, active states, and critical brand moments. It represents growth and stability.
- **Secondary (Muted Teal):** Used for data visualization and subtle accents that don't require the intensity of the primary color.
- **Neutral (Deep Charcoal):** Provides high-contrast legibility for all text and structural iconography.
- **Surface:** An off-white background reduces eye strain and distinguishes the product from standard "bleached" white interfaces.

**Dark Mode:** The interface shifts to a deep charcoal background (#1A1C1D). The teal accents are desaturated by 15% to maintain accessibility and prevent "vibrating" against the dark canvas.

## Typography
This design system utilizes **Inter** exclusively to ensure a systematic and utilitarian feel. The hierarchy relies on weight and optical sizing rather than font switching.

- **Headlines:** Use tight letter-spacing and semi-bold weights to create a strong anchor for the page.
- **Body:** Set with generous line-height to ensure the long lists of transactions remain readable and airy.
- **Labels:** Small labels use an uppercase treatment with increased tracking to provide clear categorization without overwhelming the visual field.

## Layout & Spacing
The layout follows a **8px soft-grid** system. 

- **Desktop:** A 12-column centered grid with a 1200px max-width. Side margins are fluid, but internal gutters remain fixed at 24px.
- **Mobile:** A single-column layout with 24px side margins.
- **Rhythm:** Vertical spacing is intentionally "loose." Components are separated by larger-than-average gaps (40px between major sections) to reinforce the distraction-free narrative. Elements related to the same data point (e.g., a transaction title and its date) use a 4px or 8px gap.

## Elevation & Depth
In this design system, depth is communicated through **Tonal Layers** and extremely **Soft Shadows**. 

Avoid heavy dropshadows. Instead, use a "lift" effect:
- **Level 0 (Background):** The base off-white/charcoal surface.
- **Level 1 (Cards/Containers):** A slightly lighter/darker tonal shift or a 1px stroke (opacity 8%) with a 12px blur, 4px Y-offset shadow at 4% opacity.
- **Level 2 (Modals/Popovers):** Higher contrast shadow (8% opacity) to signify immediate interaction requirement.

The goal is for elements to appear as if they are resting softly on a physical surface, not floating in space.

## Shapes
The shape language is consistently "Rounded" to soften the clinical nature of financial data.

- **Standard Containers:** Cards and input fields use a 0.5rem (8px) radius.
- **Large Elements:** Featured charts or "hero" containers use 1rem (16px).
- **Interactive Pill-shapes:** Buttons and category chips use a fully rounded (pill) radius to distinguish them from informational containers.

## Components

- **Buttons:** Primary buttons are pill-shaped, filled with Deep Teal, and use white text. Secondary buttons use a ghost style with a Deep Teal 1px stroke.
- **Category Chips:** Use the pill-shaped geometry. Backgrounds should be a very pale version of the category color (10% opacity) with text in the Deep Charcoal for maximum legibility.
- **Data Visualization:** Use "Clean Horizontal Bars" for budget progress. These bars should have rounded caps and a height of 8px. The "track" should be a 5% opacity version of the neutral color.
- **Inputs:** Use a "Modern Underline" or "Soft Box" style. Avoid heavy borders; use a subtle 1px bottom stroke that thickens/darkens on focus.
- **Lists:** Transaction lists should be borderless, using 16px vertical padding between items and a hairline divider (opacity 5%) to separate entries.
- **Cards:** Cards should have no border, utilizing only the Level 1 elevation shadow and the subtle surface color shift to define their boundaries.