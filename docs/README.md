# GitHub Pages Setup for MyLiCuLa

This directory contains the GitHub Pages website for the MyLiCuLa project.

## Setup Instructions

### 1. Enable GitHub Pages

1. Go to your repository on GitHub: `https://github.com/franciscoguemes/mylicula`
2. Click on **Settings** (in the repository navigation bar)
3. Scroll down to **Pages** in the left sidebar
4. Under **Source**, select:
   - **Branch**: `main` (or `master`)
   - **Folder**: `/docs`
5. Click **Save**

### 2. Access Your Website

After enabling GitHub Pages, your website will be available at:
- `https://franciscoguemes.github.io/mylicula/`

**Note:** It may take a few minutes for the site to be published after the first setup.

### 3. Custom Domain / Subdomain (Optional)

Yes! You can use a subdomain like `mylicula.example.com` even if `example.com` points to another website.

**Step 1: Create CNAME file**
1. Create a file named `CNAME` in the `docs/` directory
2. Add your subdomain name (e.g., `mylicula.example.com`)
   - **Important:** Only include the subdomain, no `http://` or `https://`
   - **Note:** I've created a template file - edit it with your actual subdomain

**Step 2: Configure DNS Records**
Add a CNAME record in your DNS provider's settings:

```
Type: CNAME
Name: mylicula        (or just the subdomain part)
Value: franciscoguemes.github.io
TTL: 3600 (or your provider's default)
```

**Step 3: Enable in GitHub**
1. Go to repository Settings > Pages
2. Under "Custom domain", enter your subdomain: `mylicula.example.com`
3. Check "Enforce HTTPS" (recommended)
4. Click Save

**Step 4: Wait for DNS Propagation**
- DNS changes can take 24-48 hours to propagate globally
- GitHub will verify the DNS and enable HTTPS automatically
- You can check DNS propagation with: `dig mylicula.example.com CNAME`

**Important Notes:**
- The CNAME file must contain ONLY the subdomain name (no trailing slash, no protocol)
- You can have multiple subdomains pointing to different GitHub Pages sites
- Your main domain (`example.com`) can continue pointing to your personal website
- GitHub Pages supports both apex domains (`example.com`) and subdomains (`mylicula.example.com`)

## File Structure

```
docs/
├── index.html      # Main website page
├── styles.css      # Stylesheet
├── CNAME           # Custom domain/subdomain configuration
├── README.md       # This file
├── test_website.sh # Local test server script
└── favicon.ico     # Website icon (optional)
```

## Making Changes

1. Edit the HTML/CSS files in the `docs/` directory
2. Commit and push your changes:
   ```bash
   git add docs/
   git commit -m "Update website content"
   git push
   ```
3. GitHub Pages will automatically rebuild the site (usually within a few minutes)

## Testing Locally

You can test the website locally before pushing:

### Using Python (Simple HTTP Server)

```bash
cd docs
python3 -m http.server 8000
# Or for Python 2:
python -m SimpleHTTPServer 8000
```

Then open `http://localhost:8000` in your browser.

### Using Node.js (http-server)

```bash
npm install -g http-server
cd docs
http-server
```

## Customization

- **Colors**: Edit CSS variables in `styles.css` (`:root` section)
- **Content**: Edit `index.html` to update text, sections, and structure
- **Styling**: Modify `styles.css` to change appearance

## Troubleshooting

### Site Not Updating
- Wait a few minutes (GitHub Pages can take 1-10 minutes to rebuild)
- Check GitHub Actions/Pages build logs in repository Settings > Pages
- Ensure files are in the `docs/` directory
- Verify the branch and folder settings in Pages settings

### 404 Errors
- Ensure `index.html` exists in the `docs/` directory
- Check that GitHub Pages is enabled and pointing to `/docs` folder
- Verify the repository is public (or you have GitHub Pro for private repos)

### Styling Issues
- Check browser console for CSS loading errors
- Ensure `styles.css` path is correct in `index.html`
- Clear browser cache

## Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Pages Jekyll Themes](https://pages.github.com/themes/) (if you want to use Jekyll instead)
- [Custom Domain Setup](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
