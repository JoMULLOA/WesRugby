// Simulamos datos de prueba como si vinieran de un Excel
const datosEjemplo = [
  {
    rut: '11.223.344-5',
    nombre: 'Juan Pablo González Pérez',
    curso: '1° Medio A',
    fechaNacimiento: '2008-03-15',
    direccion: 'Av. Principal 123',
    telefono: '+56912345678',
    email: 'juan.gonzalez@estudiante.wessex.cl',
    contactoEmergencia: 'Carlos González',
    telefonoEmergencia: '+56987654321',
    nombreResponsable: 'Carlos González López',
    rutResponsable: '12.345.678-9',
    nombreResponsable2: 'María Pérez Silva',
    rutResponsable2: '98.765.432-1',
    observaciones: 'Ninguna'
  },
  {
    rut: '22.334.455-6',
    nombre: 'Ana María Rodríguez Silva',
    curso: '2° Medio B',
    fechaNacimiento: '2007-07-22',
    direccion: 'Calle Secundaria 456',
    telefono: '+56923456789',
    email: 'ana.rodriguez@estudiante.wessex.cl',
    contactoEmergencia: 'Pedro Rodríguez',
    telefonoEmergencia: '+56976543210',
    nombreResponsable: 'Pedro Rodríguez Martínez',
    rutResponsable: '23.456.789-0',
    nombreResponsable2: 'Laura Silva Torres',
    rutResponsable2: '87.654.321-0',
    observaciones: 'Tiene alergia a frutos secos'
  }
];

console.log('Datos de ejemplo preparados:');
console.log(JSON.stringify(datosEjemplo, null, 2));

console.log('\n📧 Emails que se generarán automáticamente:');
datosEjemplo.forEach(estudiante => {
  const generateEmail = (nombreCompleto) => {
    const nombres = nombreCompleto.toLowerCase().split(' ');
    const primerNombre = nombres[0];
    const primerApellido = nombres[nombres.length - 2] || nombres[nombres.length - 1];
    return `${primerNombre}.${primerApellido}0@wessex.cl`;
  };
  
  console.log(`  👤 ${estudiante.nombreResponsable} → ${generateEmail(estudiante.nombreResponsable)}`);
  if (estudiante.nombreResponsable2) {
    console.log(`  👤 ${estudiante.nombreResponsable2} → ${generateEmail(estudiante.nombreResponsable2)}`);
  }
  console.log('');
});

console.log('Este script simula datos que vendrían de un archivo Excel.');
console.log('Los datos están listos para ser procesados por el controlador de importación.');