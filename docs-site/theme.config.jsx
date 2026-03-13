export default {
  logo: <span style={{ fontWeight: 700, fontSize: '1.2rem' }}>XCFramework CLI</span>,
  project: {
    link: 'https://github.com/phuongddx/xcframework-cli'
  },
  docsRepositoryBase: 'https://github.com/phuongddx/xcframework-cli/tree/main/docs-site',
  useNextSeoProps() {
    return {
      titleTemplate: '%s – XCFramework CLI'
    }
  },
  sidebar: {
    defaultMenuCollapseLevel: 1,
    toggleButton: true
  },
  navbar: {
    extraContent: (
      <a href="https://github.com/phuongddx/xcframework-cli" target="_blank" rel="noopener noreferrer">
        GitHub
      </a>
    )
  },
  footer: {
    text: (
      <span>
        MIT {new Date().getFullYear()} ©{' '}
        <a href="https://github.com/phuongddx/xcframework-cli" target="_blank" rel="noopener noreferrer">
          XCFramework CLI
        </a>
      </span>
    )
  },
  darkMode: true,
  nextThemes: {
    defaultTheme: 'system',
    forcedTheme: null
  },
  primaryHue: 210,
  primarySaturation: 80,
  search: {
    placeholder: 'Search documentation...'
  },
  editLink: {
    text: 'Edit this page on GitHub →'
  },
  toc: {
    backToTop: true
  },
  feedback: {
    content: 'Question? Give us feedback →',
    labels: 'feedback'
  },
  // Enable code highlighting with Shiki (Ruby support built-in)
  codeHighlight: true
}
