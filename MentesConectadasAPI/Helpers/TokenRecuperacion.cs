// ===== TOKEN DE RECUPERACIÓN DE CONTRASEÑA =====


using System.Security.Cryptography;
using System.Text;

namespace MentesConectadasAPI.Helpers
{
    public record DatosRecuperacion(int IdUsuario, string Huella);

    public static class TokenRecuperacion
    {
        private const string Proposito = "recuperacion";

        public static string Crear(int idUsuario, string contrasenaGuardada, string clave, TimeSpan duracion)
        {
            long expira = DateTimeOffset.UtcNow.Add(duracion).ToUnixTimeSeconds();
            string huella = Huella(contrasenaGuardada, clave);
            string datos = Base64Url(Encoding.UTF8.GetBytes($"{Proposito}|{idUsuario}|{expira}|{huella}"));
            return datos + "." + Base64Url(Firmar(datos, clave));
        }

        public static DatosRecuperacion? Leer(string? token, string clave)
        {
            if (string.IsNullOrWhiteSpace(token) || string.IsNullOrEmpty(clave) || token.Length > 400) return null;

            string[] partes = token.Trim().Split('.');
            if (partes.Length != 2) return null;

            try
            {
                byte[] firmaEsperada = Firmar(partes[0], clave);
                byte[] firmaRecibida = DeBase64Url(partes[1]);
                if (!CryptographicOperations.FixedTimeEquals(firmaEsperada, firmaRecibida)) return null;

                string[] campos = Encoding.UTF8.GetString(DeBase64Url(partes[0])).Split('|');
                if (campos.Length != 4 || campos[0] != Proposito) return null;
                if (!int.TryParse(campos[1], out int id)) return null;
                if (!long.TryParse(campos[2], out long expira) || expira <= DateTimeOffset.UtcNow.ToUnixTimeSeconds()) return null;

                return new DatosRecuperacion(id, campos[3]);
            }
            catch (FormatException)
            {
                return null;
            }
        }

        public static bool HuellaCoincide(string huellaDelToken, string contrasenaGuardada, string clave)
        {
            byte[] a = Encoding.UTF8.GetBytes(huellaDelToken ?? string.Empty);
            byte[] b = Encoding.UTF8.GetBytes(Huella(contrasenaGuardada, clave));
            return a.Length == b.Length && CryptographicOperations.FixedTimeEquals(a, b);
        }

        private static string Huella(string contrasenaGuardada, string clave)
        {
            using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(clave + "|huella"));
            string completa = Base64Url(hmac.ComputeHash(Encoding.UTF8.GetBytes(contrasenaGuardada ?? string.Empty)));
            return completa.Substring(0, 16);
        }

        private static byte[] Firmar(string texto, string clave)
        {
            using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(clave + "|" + Proposito));
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
