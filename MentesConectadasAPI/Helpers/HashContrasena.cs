// ===== CONTRASEÑAS =====

using System.Security.Cryptography;

namespace MentesConectadasAPI.Helpers
{
    public static class HashContrasena
    {
        private const int Iteraciones = 100000;
        private const int TamanoSal = 16;
        private const int TamanoHash = 32;

        public static string Hashear(string contrasena)
        {
            byte[] sal = RandomNumberGenerator.GetBytes(TamanoSal);
            byte[] hash = Rfc2898DeriveBytes.Pbkdf2(contrasena, sal, Iteraciones, HashAlgorithmName.SHA256, TamanoHash);
            return $"{Iteraciones}.{Convert.ToBase64String(sal)}.{Convert.ToBase64String(hash)}";
        }

        public static bool Verificar(string contrasena, string guardada)
        {
            string[] partes = (guardada ?? string.Empty).Split('.');
            if (partes.Length != 3 || !int.TryParse(partes[0], out int iteraciones) || iteraciones < 1) return false;

            try
            {
                byte[] sal = Convert.FromBase64String(partes[1]);
                byte[] esperado = Convert.FromBase64String(partes[2]);
                byte[] calculado = Rfc2898DeriveBytes.Pbkdf2(contrasena, sal, iteraciones, HashAlgorithmName.SHA256, esperado.Length);
                return CryptographicOperations.FixedTimeEquals(calculado, esperado);
            }
            catch (FormatException)
            {
                return false;
            }
        }
    }
}