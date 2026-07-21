// Pago en línea (opcional) por el portal de recaudo de Davivienda.
//
// Importante: el portal NO acepta el monto por la URL ni por parámetros, y está
// protegido con reCAPTCHA, así que no se puede autocompletar el "Total a pagar"
// desde fuera. Lo máximo posible sin una integración/pasarela real es copiarle
// el valor al portapapeles para que el cliente solo lo pegue en el portal.
export const DAVIVIENDA_PAYMENT_URL =
  "https://portalpagos.davivienda.com/#/comercio/8475/LA%20VIDA%20SABE%20A%20PANISSE%20S%20A%20S";

// Transferencia bancaria directa (alternativa al portal de recaudo).
export const BANK_TRANSFER = {
  bank: "Banco Davivienda",
  type: "Cuenta de Ahorros",
  number: "108900430654",
  holder: "LA VIDA SABE A PANISSE S.A.S.",
};
