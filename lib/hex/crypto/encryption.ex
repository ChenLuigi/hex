defmodule Hex.Crypto.Encryption do
  @moduledoc false
  alias Hex.Crypto
  alias Hex.Crypto.ContentEncryptor
  alias Hex.Crypto.KeyManager

  def encrypt({tag, plain_text}, protected, opts) do
    case KeyManager.encrypt(protected, opts) do
      {:ok, protected, key, encrypted_key, content_encryptor} ->
        iv = ContentEncryptor.generate_iv(content_encryptor)
        protected = :erlang.term_to_binary(protected)
        aad = tag <> protected

        {cipher_text, cipher_tag} =
          ContentEncryptor.encrypt(content_encryptor, key, iv, {aad, plain_text})

        %{
          protected: protected,
          encrypted_key: encrypted_key,
          iv: iv,
          cipher_text: cipher_text,
          cipher_tag: cipher_tag
        }
        |> :erlang.term_to_binary()
        |> Crypto.base64url_encode()

      encrypt_init_error ->
        encrypt_init_error
    end
  end

  def decrypt({tag, cipher_text}, opts) do
    {:ok, cipher_text} = Crypto.base64url_decode(cipher_text)

    %{
      protected: protected,
      encrypted_key: encrypted_key,
      iv: iv,
      cipher_text: cipher_text,
      cipher_tag: cipher_tag
    } = Hex.Utils.safe_binary_to_term!(cipher_text, [:safe])

    aad = tag <> protected
    protected = Hex.Utils.safe_binary_to_term!(protected, [:safe])

    case KeyManager.decrypt(protected, encrypted_key, opts) do
      {:ok, key, content_encryptor} ->
        ContentEncryptor.decrypt(content_encryptor, key, iv, {aad, cipher_text, cipher_tag})

      decrypt_init_error ->
        decrypt_init_error
    end
  rescue
    ArgumentError ->
      :error
  end
end
