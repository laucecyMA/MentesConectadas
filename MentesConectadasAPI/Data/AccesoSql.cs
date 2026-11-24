// ===== ACCESO A SQL SERVER =====

using System.Data;
using System.Data.SqlClient;

namespace MentesConectadasAPI.Data
{
    public class AccesoSql
    {
        private readonly string _cadena;

        public AccesoSql(IConfiguration configuration)
        {
            _cadena = configuration.GetConnectionString("CadenaSQL") ?? string.Empty;
        }

        public async Task EjecutarAsync(string procedimiento, params SqlParameter[] parametros)
        {
            using var conexion = new SqlConnection(_cadena);
            await conexion.OpenAsync();
            using var comando = Crear(conexion, procedimiento, parametros);
            await comando.ExecuteNonQueryAsync();
        }

        public async Task<List<T>> ConsultarAsync<T>(string procedimiento, Func<SqlDataReader, T> convertir, params SqlParameter[] parametros)
        {
            var lista = new List<T>();
            using var conexion = new SqlConnection(_cadena);
            await conexion.OpenAsync();
            using var comando = Crear(conexion, procedimiento, parametros);
            using var lector = await comando.ExecuteReaderAsync();
            while (await lector.ReadAsync())
            {
                lista.Add(convertir(lector));
            }
            return lista;
        }

        public async Task ConsultarVariosAsync(string procedimiento, Func<SqlDataReader, Task> leer, params SqlParameter[] parametros)
        {
            using var conexion = new SqlConnection(_cadena);
            await conexion.OpenAsync();
            using var comando = Crear(conexion, procedimiento, parametros);
            using var lector = await comando.ExecuteReaderAsync();
            await leer(lector);
        }

        public static SqlParameter SalidaInt(string nombre) =>
            new SqlParameter(nombre, SqlDbType.Int) { Direction = ParameterDirection.Output };

        public static SqlParameter SalidaTexto(string nombre, int tamano = 1000) =>
            new SqlParameter(nombre, SqlDbType.VarChar, tamano) { Direction = ParameterDirection.Output };

        public static SqlParameter Param(string nombre, object? valor) => new SqlParameter(nombre, valor ?? DBNull.Value);

        private static SqlCommand Crear(SqlConnection conexion, string procedimiento, SqlParameter[] parametros)
        {
            var comando = new SqlCommand(procedimiento, conexion) { CommandType = CommandType.StoredProcedure };
            foreach (var parametro in parametros)
            {
                comando.Parameters.Add(parametro);
            }
            return comando;
        }
    }
}