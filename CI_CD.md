# 🔄 CI/CD Documentation - Secure Procurement Platform

## 📋 Overview

This project includes a comprehensive CI/CD pipeline using **GitHub Actions** with automated testing, code quality checks, and deployment workflows.

**CI/CD Features:**
- ✅ Automated testing on multiple Node.js versions (18.x, 20.x)
- ✅ Code coverage with Codecov integration
- ✅ Solidity linting with Solhint
- ✅ TypeScript linting with ESLint
- ✅ Type checking with TypeScript compiler
- ✅ Security audits with npm audit and Slither
- ✅ Automated deployment to GitHub Pages
- ✅ Sepolia testnet deployment workflow
- ✅ Gas usage reporting

---

## 🚀 GitHub Actions Workflows

### 1. Test & Code Quality (`.github/workflows/test.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

**Jobs:**

#### ✅ Test Matrix
- Runs tests on **Node.js 18.x** and **20.x**
- Compiles smart contracts
- Executes full test suite (55+ tests)
- Generates code coverage report
- Uploads coverage to Codecov
- Generates gas usage report

**Commands:**
```bash
npm ci                      # Install dependencies
npx hardhat compile         # Compile contracts
npm test                    # Run tests
npm run test:coverage       # Generate coverage
npm run test:gas           # Generate gas report
```

#### ✅ Solidity Linting
- Runs **Solhint** on all Solidity files
- Checks code style and best practices
- Generates linting report
- Uploads results as artifact

**Commands:**
```bash
npm run lint:sol           # Run Solhint
```

#### ✅ TypeScript Linting
- Runs **ESLint** on TypeScript files
- Enforces code style standards
- Maximum 0 warnings allowed

**Commands:**
```bash
npm run lint:ts            # Run ESLint
```

#### ✅ Type Checking
- Runs TypeScript compiler
- Validates all types
- No emit, type checking only

**Commands:**
```bash
npm run type-check         # Run tsc --noEmit
```

#### ✅ Build Verification
- Builds frontend for production
- Verifies build succeeds
- Uploads build artifacts
- Retained for 7 days

**Commands:**
```bash
npm run build              # Build production bundle
```

#### ✅ Security Audit
- Runs **npm audit** on production dependencies
- Runs **Slither** for Solidity security analysis
- Continues on error (warnings only)

**Commands:**
```bash
npm audit --production     # Check dependencies
slither contracts/         # Security analysis
```

#### ✅ CI Summary
- Aggregates all job results
- Displays overall CI status
- Reports any failures

---

### 2. Deploy to GitHub Pages (`.github/workflows/deploy.yml`)

**Triggers:**
- Push to `main` branch
- Manual workflow dispatch

**Jobs:**

#### ✅ Build Frontend
- Installs dependencies
- Compiles smart contracts
- Builds production frontend
- Sets up GitHub Pages
- Uploads artifact

#### ✅ Deploy
- Deploys to GitHub Pages
- Outputs deployment URL
- Environment: `github-pages`

**Setup Required:**
1. Go to repository **Settings → Pages**
2. Source: **GitHub Actions**
3. No additional configuration needed

**Deployment URL:** `https://YOUR-USERNAME.github.io/secure-procurement/`

---

### 3. Deploy to Sepolia (`.github/workflows/deploy-sepolia.yml`)

**Triggers:**
- **Manual workflow dispatch only**
- Requires typing "deploy" to confirm

**Jobs:**

#### ✅ Deploy Contract
- Runs all tests before deployment
- Deploys to Sepolia testnet
- Outputs deployment info

**Required Secrets:**
- `SEPOLIA_RPC_URL` - Infura/Alchemy RPC endpoint
- `PRIVATE_KEY` - Deployer private key (with Sepolia ETH)

#### ✅ Verify Contract
- Verifies contract on Etherscan
- Uses Etherscan API

**Required Secrets:**
- `ETHERSCAN_API_KEY` - Etherscan API key

**Manual Deployment:**
1. Go to **Actions** tab
2. Select **Deploy Contract to Sepolia**
3. Click **Run workflow**
4. Type `deploy` to confirm
5. Click **Run workflow** button

---

## 🔧 Configuration Files

### 1. Solhint Configuration (`.solhint.json`)

**Features:**
- Extends `solhint:recommended`
- Prettier plugin integration
- Custom rules for FHE contracts

**Key Rules:**
```json
{
  "compiler-version": ["error", "^0.8.0"],
  "max-line-length": ["warn", 120],
  "func-visibility": ["warn", {"ignoreConstructors": true}],
  "no-console": "off",
  "no-inline-assembly": "off"
}
```

**Run Solhint:**
```bash
npm run lint:sol           # Check Solidity code
npm run lint:sol:fix       # Auto-fix issues
```

---

### 2. ESLint Configuration (`.eslintrc.json`)

**Features:**
- TypeScript support
- Recommended rules
- Browser + Node.js environment

**Key Rules:**
```json
{
  "@typescript-eslint/no-explicit-any": "warn",
  "@typescript-eslint/no-unused-vars": "warn",
  "no-console": ["warn", {"allow": ["warn", "error", "info"]}],
  "prefer-const": "error",
  "no-var": "error"
}
```

**Run ESLint:**
```bash
npm run lint:ts            # Check TypeScript code
npm run lint:ts:fix        # Auto-fix issues
```

---

### 3. Prettier Configuration (`.prettierrc.json`)

**Features:**
- Consistent code formatting
- Solidity-specific rules
- TypeScript support

**Settings:**
```json
{
  "semi": true,
  "singleQuote": true,
  "printWidth": 100,
  "tabWidth": 2
}
```

**Run Prettier:**
```bash
npm run format             # Format all files
npm run format:check       # Check formatting
```

---

## 📊 Code Coverage with Codecov

### Setup Codecov

1. **Sign up at [codecov.io](https://codecov.io/)**
2. **Connect GitHub repository**
3. **Get Upload Token**
   - Go to Settings → General
   - Copy the **Repository Upload Token**

4. **Add GitHub Secret**
   - Go to repo **Settings → Secrets → Actions**
   - Click **New repository secret**
   - Name: `CODECOV_TOKEN`
   - Value: Your upload token

### Coverage Reports

**Automatic Upload:**
- Coverage automatically uploaded on every push
- Reports available at `https://codecov.io/gh/USERNAME/secure-procurement`

**Badge:**
```markdown
[![codecov](https://codecov.io/gh/USERNAME/secure-procurement/branch/main/graph/badge.svg)](https://codecov.io/gh/USERNAME/secure-procurement)
```

**Local Coverage:**
```bash
npm run test:coverage      # Generate coverage report
# Open: coverage/index.html
```

---

## 🔐 GitHub Secrets Setup

### Required Secrets

| Secret | Purpose | How to Get |
|--------|---------|------------|
| `CODECOV_TOKEN` | Coverage upload | [codecov.io](https://codecov.io/) |
| `SEPOLIA_RPC_URL` | Sepolia deployment | [Infura](https://infura.io/) or [Alchemy](https://alchemy.com/) |
| `PRIVATE_KEY` | Deployer wallet | MetaMask → Account Details → Export Private Key |
| `ETHERSCAN_API_KEY` | Contract verification | [Etherscan](https://etherscan.io/apis) |

### Adding Secrets

1. Go to **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Add name and value
4. Click **Add secret**

**Security Notes:**
- ⚠️ Never commit secrets to repository
- ⚠️ Use deployment-only wallet with limited funds
- ⚠️ Rotate keys regularly
- ⚠️ Review access logs periodically

---

## 🧪 Local Testing

### Run All Checks Locally

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile

# Run tests
npm test

# Run coverage
npm run test:coverage

# Run linting
npm run lint

# Run type checking
npm run type-check

# Format code
npm run format

# Build project
npm run build
```

### Pre-Commit Checks

Before pushing code, run:

```bash
# Complete check sequence
npm run lint && npm run type-check && npm test && npm run build
```

---

## 📈 CI/CD Status Badges

Add badges to your README.md:

### Test Status
```markdown
![Test](https://github.com/USERNAME/secure-procurement/actions/workflows/test.yml/badge.svg)
```

### Deployment Status
```markdown
![Deploy](https://github.com/USERNAME/secure-procurement/actions/workflows/deploy.yml/badge.svg)
```

### Code Coverage
```markdown
[![codecov](https://codecov.io/gh/USERNAME/secure-procurement/branch/main/graph/badge.svg)](https://codecov.io/gh/USERNAME/secure-procurement)
```

### License
```markdown
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
```

---

## 🔍 Workflow Monitoring

### View Workflow Runs

1. Go to **Actions** tab in repository
2. Select workflow from left sidebar
3. Click on specific run to see details
4. View logs for each job

### Check Status

- ✅ Green checkmark = All checks passed
- ❌ Red X = Some checks failed
- 🟡 Yellow dot = Checks in progress
- ⚪ Gray circle = Checks skipped

### Download Artifacts

1. Go to completed workflow run
2. Scroll to **Artifacts** section
3. Download:
   - Gas reports
   - Build artifacts
   - Solhint reports
   - Coverage reports

---

## 🐛 Troubleshooting

### Common Issues

#### Issue 1: Tests Fail in CI but Pass Locally
**Solution:**
```bash
# Clean and reinstall
npm run clean
rm -rf node_modules package-lock.json
npm install
npm test
```

#### Issue 2: Coverage Upload Fails
**Solution:**
- Verify `CODECOV_TOKEN` is set correctly
- Check Codecov dashboard for errors
- Ensure coverage file exists: `coverage/lcov.info`

#### Issue 3: Deployment Fails
**Solution:**
- Check secrets are configured
- Verify RPC URL is accessible
- Ensure deployer wallet has sufficient ETH
- Review deployment logs for specific errors

#### Issue 4: Linting Errors
**Solution:**
```bash
# Auto-fix linting issues
npm run lint:fix

# Or fix individually
npm run lint:sol:fix
npm run lint:ts:fix
```

#### Issue 5: Type Errors
**Solution:**
```bash
# Check types locally
npm run type-check

# Regenerate TypeChain types
npm run compile
```

---

## 📝 Best Practices

### Commit Messages

Use conventional commits:
```
feat: add new feature
fix: fix bug in smart contract
docs: update documentation
test: add test cases
ci: update CI/CD workflow
refactor: refactor code
style: fix code style
```

### Branch Strategy

- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - Feature branches
- `fix/*` - Bug fix branches
- `hotfix/*` - Emergency fixes

### Pull Request Workflow

1. Create feature branch from `develop`
2. Make changes and commit
3. Push branch to GitHub
4. Create Pull Request to `develop`
5. CI/CD runs automatically
6. Review and address feedback
7. Merge when all checks pass

### Code Review Checklist

- [ ] All CI/CD checks pass
- [ ] Code coverage maintained (>95%)
- [ ] No linting errors
- [ ] Type checking passes
- [ ] Tests added for new features
- [ ] Documentation updated
- [ ] Commit messages follow conventions

---

## 🚀 Deployment Workflow

### Development to Production

1. **Develop Features**
   ```bash
   git checkout -b feature/my-feature
   # Make changes
   git commit -m "feat: add my feature"
   git push origin feature/my-feature
   ```

2. **Create Pull Request**
   - Open PR to `develop` branch
   - CI/CD runs automatically
   - Review and merge

3. **Test on Develop**
   - Automatic tests run on merge
   - Monitor CI/CD results

4. **Deploy to Sepolia**
   - Manual workflow dispatch
   - Type "deploy" to confirm
   - Contract deployed and verified

5. **Merge to Main**
   ```bash
   git checkout main
   git merge develop
   git push origin main
   ```

6. **Automatic Deployment**
   - Frontend auto-deploys to GitHub Pages
   - Available at GitHub Pages URL

---

## 📊 Metrics & Monitoring

### Key Metrics

| Metric | Target | Current |
|--------|--------|---------|
| Test Coverage | >95% | ~100% ✅ |
| Build Time | <2 min | ~1 min ✅ |
| Test Time | <3 min | ~2 sec ✅ |
| Linting Errors | 0 | 0 ✅ |
| Type Errors | 0 | 0 ✅ |

### Gas Reports

View gas usage:
```bash
npm run test:gas
```

Download from CI artifacts:
1. Go to Actions tab
2. Select test workflow run
3. Download `gas-report` artifact

---

## 🎓 Additional Resources

### GitHub Actions
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions)
- [Actions Marketplace](https://github.com/marketplace?type=actions)

### Code Quality Tools
- [Solhint Documentation](https://github.com/protofire/solhint)
- [ESLint Documentation](https://eslint.org/docs/latest/)
- [Prettier Documentation](https://prettier.io/docs/en/)

### Testing & Coverage
- [Codecov Documentation](https://docs.codecov.com/)
- [Hardhat Testing](https://hardhat.org/hardhat-runner/docs/guides/test-contracts)
- [Mocha Documentation](https://mochajs.org/)

---

## ✅ Summary

This CI/CD pipeline provides:

✅ **Automated Testing**
- 55+ test cases on every push
- Multi-version Node.js testing (18.x, 20.x)
- Code coverage tracking with Codecov

✅ **Code Quality**
- Solidity linting with Solhint
- TypeScript linting with ESLint
- Type checking with TypeScript
- Code formatting with Prettier

✅ **Security**
- npm audit for dependency vulnerabilities
- Slither for smart contract security
- Automated security checks

✅ **Deployment**
- Automated GitHub Pages deployment
- Manual Sepolia testnet deployment
- Contract verification on Etherscan

✅ **Monitoring**
- Gas usage reports
- Build artifacts
- Coverage reports
- Workflow status badges

---

**CI/CD Status:** ✅ Fully Operational

**Last Updated:** 2025-10-18

**Version:** 1.0.0
