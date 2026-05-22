# Estágio de construção baseado no Ubuntu estável
FROM ubuntu:22.04

# Evita prompts interativos durante as instalações de pacotes
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependências de sistema necessárias para compilação multiplataforma
RUN apt-get update && apt-get install -y     curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk wget clang cmake ninja-build pkg-config libgtk-3-dev

# Configurar e provisionar as ferramentas de linha de comando do Android SDK
ENV ANDROID_HOME="/usr/local/android-sdk"
RUN mkdir -p $ANDROID_HOME/cmdline-tools &&     wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O sdk.zip &&     unzip sdk.zip -d $ANDROID_HOME/cmdline-tools &&     mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest &&     rm sdk.zip

# Mapeamento das ferramentas do SDK para a variável de ambiente PATH
ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0

# Aceitar termos de licença e instalar dependências do ecossistema Android
RUN yes | sdkmanager --licenses
RUN sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Clonar e configurar o canal estável do framework Flutter
RUN git clone -b stable https://github.com/flutter/flutter.git /usr/local/flutter
ENV PATH=$PATH:/usr/local/flutter/bin

# Configurações internas de consentimento e validação de licenças nativas
RUN flutter config --no-analytics &&     flutter doctor --android-licenses &&     flutter doctor

# Mapear diretório de trabalho e copiar os fontes da aplicação
WORKDIR /app
COPY . .

# Obter pacotes do pubspec e restabelecer as configurações estruturais nativas do Android
RUN flutter pub get
RUN flutter create . --platforms android

# Iniciar compilação da versão de distribuição do binário (APK)
RUN flutter build apk --release