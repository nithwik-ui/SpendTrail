---
name: SpendTrail
colors:
  surface: '#fcf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fcf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae7e7'
  surface-container-highest: '#e4e2e1'
  on-surface: '#1b1c1c'
  on-surface-variant: '#3e494a'
  inverse-surface: '#303030'
  inverse-on-surface: '#f3f0f0'
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
  tertiary: '#743b24'
  on-tertiary: '#ffffff'
  tertiary-container: '#915239'
  on-tertiary-container: '#ffd7c9'
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
  tertiary-fixed: '#ffdbce'
  tertiary-fixed-dim: '#ffb59a'
  on-tertiary-fixed: '#380d00'
  on-tertiary-fixed-variant: '#6f3720'
  background: '#fcf9f8'
  on-background: '#1b1c1c'
  surface-variant: '#e4e2e1'
typography:
  display-currency:
    fontFamily: Montserrat
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -1px
  headline-lg:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-md:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-sm:
    fontFamily: Montserrat
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.5px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  headline-lg-mobile:
    fontFamily: Montserrat
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  margin-mobile: 20px
  gutter-mobile: 12px
---

## Brand & Style
The design system is built on a **Warm Minimalist** aesthetic that mimics the tactile, inviting quality of a personal physical notebook. It targets Indian college students who need a tool that feels less like a banking app and more like a trusted companion. 

The visual language avoids corporate coldness by using a cream-based palette and generous negative space. The style utilizes subtle depth—rather than heavy shadows—to maintain a "flat but layered" feel, ensuring the interface remains lightweight and fast on various mobile devices. The emotional response should be one of clarity and calm, removing the anxiety often associated with expense tracking.

## Colors
The color palette is anchored by an off-white/cream background to reduce eye strain and provide a "paper" feel. 

- **Primary (Deep Teal):** Used for primary actions, active navigation states, and key brand moments.
- **Secondary (Soft Mint):** Used for "Income" indicators, success states, and subtle highlights.
- **Tertiary (Warm Sand):** Used for "Expense" indicators and cautionary alerts.
- **Neutral (Dark Charcoal):** Reserved for high-contrast typography and iconography to ensure legibility.
- **Background (Cream):** The foundational layer for all screens, creating a warm, non-clinical atmosphere.

## Typography
This design system uses a pairing of **Montserrat** for headers and **Inter** for functional text. 

- **Currency Display:** Use `display-currency` for the main balance. Always use the ₹ (INR) symbol. Numbers should be prominent and bold.
- **Headers:** Montserrat provides a geometric, friendly authority. Use `headline-lg-mobile` for page titles on mobile to ensure they don't wrap awkwardly.
- **Body & Labels:** Inter is used for its high legibility in data-heavy lists and form fields. 
- **Formatting:** Adhere to the Indian Numbering System (Lakhs/Crores) for all currency strings (e.g., ₹1,20,000).

## Layout & Spacing
The layout follows a **Fluid Grid** model with a focus on mobile-first interaction. 

- **Grid:** Use a 4-column grid for mobile and a 12-column grid for desktop. 
- **Margins:** Maintain a generous 20px safe area on the horizontal edges of the screen to reinforce the "notebook" margin feel.
- **Rhythm:** Use an 8px base scaling system. Vertical spacing between logical groups (e.g., between a header and a list) should typically be 24px (`lg`).
- **Touch Targets:** Ensure all interactive elements have a minimum height of 48px for easy thumb access during on-the-go tracking.

## Elevation & Depth
In keeping with the "notebook" feel, the design system avoids heavy drop shadows. 

- **Surface Layers:** Use subtle tonal shifts rather than shadows. Cards should be slightly lighter than the cream background or use a very thin (1px) neutral border at 10% opacity.
- **Ambient Depth:** When an element must float (like a Floating Action Button), use a soft, diffused shadow: `box-shadow: 0 4px 20px rgba(0, 109, 119, 0.15)`.
- **Active State:** Elements should feel tactile. Pressing a button should result in a slight scale-down (98%) rather than a heavy shadow change.

## Shapes
Shapes are friendly and approachable, utilizing a consistent radius to maintain a modern look.

- **Standard Containers:** Use `rounded-md` (8px) for input fields and small cards.
- **Main Components:** Use `rounded-lg` (16px) for large content cards, such as monthly spend summaries.
- **Interactive Elements:** Use `rounded-xl` (24px) or full pill-shapes for primary buttons and chips to make them feel soft and touch-inviting.

## Components
- **Buttons:** Primary buttons use the Deep Teal background with White text. Use a pill shape (rounded-xl) for a friendlier, "drawn" appearance.
- **Expense Cards:** List items for transactions should have a clean, borderless look with a thin divider. The amount should be on the right in `headline-sm`.
- **Input Fields:** Soft cream background with a slightly darker stroke (Neutral at 20% opacity). Labels sit above the field in `label-sm`.
- **Chips:** Used for categories (Food, Rent, Travel). These should be outlined or have a very pale version of the accent colors (e.g., 10% opacity of Deep Teal).
- **Progress Bars:** For budget tracking, use thick, rounded bars. The background of the bar should be a 10% opacity version of the primary color to keep the UI "light."
- **Empty States:** Use simple, hand-drawn style illustrations or icons to maintain the "personal notebook" vibe when no data is present.