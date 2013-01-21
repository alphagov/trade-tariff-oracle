-- LCRR TXTLINE should be at least 74 bytes to accomodate charset conversion.
ALTER TABLE LCRR MODIFY TXTLINE VARCHAR2(74);
-- LCC9 TXTLINE should be at least 72 bytes to accomodate charset conversion.
ALTER TABLE LCC9 MODIFY TXTLINE VARCHAR2(72);
quit;