function parseReleaseDate(str) {
    if (!str) return null;
    let normalized = str;
    if (/^\d{4}$/.test(str)) {
        normalized = `${str}-01-01`;
    } else {
        const dmy = str.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
        if (dmy) {
            normalized = `${dmy[3]}-${dmy[2].padStart(2, '0')}-${dmy[1].padStart(2, '0')}`;
        }
    }
    const date = new Date(normalized);
    return isNaN(date.getTime()) ? null : date;
}
