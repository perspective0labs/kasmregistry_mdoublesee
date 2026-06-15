/** @type {import('next').NextConfig} */

const nextConfig = {
  output: 'export',
  distDir: '../public',
  env: {
    name: 'perspective0labs//mdoublesee - Kasm Registry',
    description: 'Kasm Workspaces streamning nerd bidness',
    icon: 'https://scontent.fsyd3-2.fna.fbcdn.net/v/t39.30808-1/710667072_1320148323427420_1550385609996148166_n.jpg?stp=dst-jpg_tt6&cstp=mx620x620&ctp=s200x200&_nc_cat=102&ccb=1-7&_nc_sid=2d3e12&_nc_ohc=5UgRNhTwoScQ7kNvwHT3TiE&_nc_oc=Adox69ARKiJmJ3WLJSbwD3r8bVgnVGvVgrv26B0oBdNgPsEHLE2CUUfBhhWy9UduG2U&_nc_zt=24&_nc_ht=scontent.fsyd3-2.fna&_nc_gid=I19j2NZARYmtiCCwI-DwHA&_nc_ss=7b2a8&oh=00_Af-CD13tGOOY2e-8kzbCvchXXjYUamgnJE9I7AIh7yXZnw&oe=6A361C77',
    listUrl: ' https://perspective0labs.github.io/kasmredistry_mdoublesee/',
    contactUrl: 'https://github.com/perspective0labs/kasmregistry_mdoublesee/issues',
  },
  reactStrictMode: true,
  basePath: '/kasmregistry_mdoublesee/1.0',
  trailingSlash: true,
  images: {
    unoptimized: true,
  }
}

module.exports = nextConfig
