{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE RecordWildCards #-}

module PkgBuild
  ( PkgBuild (..),
    ArchLicense,
    mapLicense,
    applyTemplate,
  )
where

import Data.Text (Text, pack, unpack)
import Distribution.SPDX.LicenseId
import NeatInterpolation (text)

data PkgBuild = PkgBuild
  { _hkgName :: String,
    _pkgName :: String,
    _pkgVer :: String,
    _pkgDesc :: String,
    _url :: String,
    _license :: String,
    _depends :: String,
    _makeDepends :: String,
    _enableCheck :: Bool
  }

data ArchLicense
  = AGPL3
  | Apache
  | Artistic2_0
  | -- | Boost
    -- | CC_BY
    -- | CC_BY_NC
    -- | CC_BY_NC_ND
    -- | CC_BY_NC_SA
    -- | CC_BY_ND
    -- | CC_BY_SA
    CDDL
  | CPL
  | EPL
  | FDL1_2
  | FDL1_3
  | GPL2
  | GPL3
  | LGPL2_1
  | LGPL3
  | LPPL
  | MPL
  | MPL2
  | PHP
  | PSF
  | PerlArtistic
  | RUBY
  | Unlicense
  | W3C
  | ZPL
  | Custom String

instance Show ArchLicense where
  show AGPL3 = "AGPL"
  show Apache = "Apache"
  show Artistic2_0 = "Artistic2.0"
  show CDDL = "CDDL"
  show CPL = "CPL"
  show EPL = "EPL"
  show FDL1_2 = "FDL1.2"
  show FDL1_3 = "FDL1.3"
  show GPL2 = "GPL2"
  show GPL3 = "GPL3"
  show LGPL2_1 = "LGPL2.1"
  show LGPL3 = "LGPL3"
  show LPPL = "LPPL"
  show MPL = "MPL"
  show MPL2 = "MPL2"
  show PHP = "PHP"
  show PSF = "PSF"
  show PerlArtistic = "PerlArtistic"
  show RUBY = "RUBY"
  show PkgBuild.Unlicense = "Unlicense"
  show PkgBuild.W3C = "W3C"
  show ZPL = "ZPL"
  show (Custom x) = "custom:" ++ x

mapLicense :: LicenseId -> ArchLicense
mapLicense AGPL_3_0_only = AGPL3
mapLicense Apache_2_0 = Apache
mapLicense Artistic_2_0 = Artistic2_0
mapLicense CDDL_1_0 = CDDL
mapLicense CPL_1_0 = CPL
mapLicense EPL_1_0 = EPL
mapLicense GFDL_1_2_only = FDL1_2
mapLicense GFDL_1_3_only = FDL1_3
mapLicense GPL_2_0_only = GPL2
mapLicense GPL_3_0_only = GPL3
mapLicense LGPL_2_1_only = LGPL2_1
mapLicense LGPL_3_0_only = LGPL3
mapLicense LPPL_1_3c = LPPL
mapLicense MPL_1_0 = MPL
mapLicense MPL_2_0 = MPL2
mapLicense PHP_3_01 = PHP
mapLicense Python_2_0 = PSF
mapLicense Artistic_1_0_Perl = PerlArtistic
mapLicense Ruby = RUBY
mapLicense ZPL_2_1 = ZPL
mapLicense Distribution.SPDX.LicenseId.Unlicense = PkgBuild.Unlicense
mapLicense Distribution.SPDX.LicenseId.W3C = PkgBuild.W3C
mapLicense BSD_3_Clause = Custom "BSD3"
mapLicense x = Custom $ show x

applyTemplate :: PkgBuild -> String
applyTemplate PkgBuild {..} =
  unpack $
    felixTemplate
      (pack _hkgName)
      (pack _pkgName)
      (pack _pkgVer)
      (pack _pkgDesc)
      (pack _url)
      (pack _license)
      (pack _depends)
      (pack _makeDepends)
      (if _enableCheck then check else "\n")

check :: Text
check =
  [text|
  check() {
    cd $$_hkgname-$$pkgver
    runhaskell Setup test
  }
|]

felixTemplate :: Text -> Text -> Text -> Text -> Text -> Text -> Text -> Text -> Text -> Text
felixTemplate hkgname pkgname pkgver pkgdesc url license depends makedepends checkF =
  [text|
  # This file was generated by arch-hs, please check it manually.
  # Maintainer: Your Name <youremail@domain.com>

  _hkgname=$hkgname
  pkgname=haskell-$pkgname
  pkgver=$pkgver
  pkgrel=1
  pkgdesc="$pkgdesc"
  url="$url"
  license=("$license")
  arch=('x86_64')
  depends=('ghc-libs' $depends)
  makedepends=('ghc' $makedepends)
  source=("https://hackage.haskell.org/packages/archive/$$_hkgname/$$pkgver/$$_hkgname-$$pkgver.tar.gz")
  sha256sums=('SKIP')

  prepare(){
    cd $$_hkgname-$$pkgver
  }

  build() {
    cd $$_hkgname-$$pkgver    

    runhaskell Setup configure -O --enable-shared --enable-executable-dynamic --disable-library-vanilla \
      --prefix=/usr --docdir=/usr/share/doc/$$pkgname --enable-tests \
      --dynlibdir=/usr/lib --libsubdir=\$$compiler/site-local/\$$pkgid \
      --ghc-option=-optl-Wl\,-z\,relro\,-z\,now \
      --ghc-option='-pie'

    runhaskell Setup build
    runhaskell Setup register --gen-script
    runhaskell Setup unregister --gen-script
    sed -i -r -e "s|ghc-pkg.*update[^ ]* |&'--force' |" register.sh
    sed -i -r -e "s|ghc-pkg.*unregister[^ ]* |&'--force' |" unregister.sh
  }

  $checkF

  package() {
    cd $$_hkgname-$$pkgver

    install -D -m744 register.sh "$$pkgdir"/usr/share/haskell/register/$$pkgname.sh
    install -D -m744 unregister.sh "$$pkgdir"/usr/share/haskell/unregister/$$pkgname.sh
    runhaskell Setup copy --destdir="$$pkgdir"
    install -D -m644 "LICENSE" "$${pkgdir}/usr/share/licenses/$${pkgname}/LICENSE"
    rm -f "$${pkgdir}/usr/share/doc/$${pkgname}/LICENSE"
  } 
|]