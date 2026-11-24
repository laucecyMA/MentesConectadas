// ===== TOKEN DE SESIÓN =====

using System.Security.Cryptography;
using System.Text;

namespace MentesConectadasAPI.Helpers
{
    public record DatosSesion(int IdUsuario, string TipoUsuario);

    public static class TokenSesion
    {
        public static string Crear(int idUsuario, string tipoUsuario, string clave, TimeSpan duracion)
        {
            long expira = DateTimeOffset.UtcNow.Add(duracion).ToUnixTimeSeconds();
            string datos = Base64Url(Encoding.UTF8.GetBytes($"{idUsuario}|{tipoUsuario}|{expira}"));
            return datos + "." + Base64Url(Firmar(datos, clave));
        }

        public static DatosSesion? Validar(string? token, string clave)
        {
            if (string.IsNullOrWhiteSpace(token) || string.IsNullOrEmpty(clave)) return null;

            string[] partes = token.Split('.');
            if (partes.Length != 2) return null;

            try
            {
                byte[] firmaEsperada = Firmar(partes[0], clave);
                byte[] firmaRecibida = DeBase64Url(partes[1]);
                if (!CryptographicOperations.FixedTimeEquals(firmaEsperada, firmaRecibida)) return null;

                string[] campos = Encoding.UTF8.GetString(DeBase64Url(partes[0])).Split('|');
                if (campos.Length != 3 || !int.TryParse(campos[0], out int id)) return null;
                if (!long.TryParse(campos[2], out long expira) || expira <= DateTimeOffset.UtcNow.ToUnixTimeSeconds()) return null;

                return new DatosSesion(id, campos[1]);
            }
            catch (FormatException)
            {
                return null;
            }
        }

        private static byte[] Firmar(string texto, string clave)
        {
            using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(clave));
            return hmac.ComputeHash(Encoding.UTF8.GetBytes(texto));
        }

        private static string Base64Url(byte[] bytes) =>
            Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');

        private static byte[] DeBase64Url(string texto)
        {
            texto = texto.Replace('-', '+').Replace('_', '/');
            switch (texto.Length % 4)
            {
                case 2: texto += "=="; break;
                case 3: texto += "="; break;
            }
            return Convert.FromBase64String(texto);
        }
    }
}