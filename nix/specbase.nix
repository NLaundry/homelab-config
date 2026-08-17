{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs_22,
  pnpm_10,
  pnpmConfigHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "specbase";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "AwareByDefault";
    repo = "specbase";
    rev = "d0ca4326cefdc7b35a6edb9daca42aa9bf7897d2";
    hash = "sha256-yDtmpX6a15dgJDEuNRf+MGzoN5dYRw+OMVIdCS1D1Ng=";
  };

  pnpmDeps = fetchPnpmDeps {
    fetcherVersion = 4;
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    hash = "sha256-mg//AmmpjMBwIP9Cc8A3ccvQqph0v1WeSpxqkPVcVws=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpm_10
    pnpmConfigHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    rm -rf node_modules
    pnpm install --offline --frozen-lockfile --prod --ignore-scripts

    packageRoot=$out/lib/node_modules/@awarebydefault/specbase
    mkdir -p "$packageRoot" $out/bin
    cp -R dist bin schemas scripts package.json LICENSE "$packageRoot/"
    cp -R node_modules "$packageRoot/"

    chmod +x "$packageRoot/bin/specbase.js" "$packageRoot/bin/openspec.js"
    patchShebangs "$packageRoot/bin"
    ln -s "$packageRoot/bin/specbase.js" $out/bin/specbase
    ln -s "$packageRoot/bin/openspec.js" $out/bin/openspec

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$($out/bin/specbase --version)" = "${finalAttrs.version}"
    runHook postInstallCheck
  '';

  meta = {
    description = "Governed specification workflow and enforcement CLI";
    homepage = "https://github.com/AwareByDefault/specbase";
    license = lib.licenses.mit;
    mainProgram = "specbase";
    platforms = lib.platforms.unix;
  };
})
