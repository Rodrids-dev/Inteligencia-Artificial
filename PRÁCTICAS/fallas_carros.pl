%- TRIAJE PARA UN MECÁNICO -%
% Autor: Rodrigo Díaz Salguero
% Fecha: 13/08/2025
% Función: Defino algunas fallas en automoviles
% como hechos para poder aplicar la programación
% lógica en PROLOG.

%----HECHOS----%
fallas(auto1,humo_escape).
fallas(auto1,perdida_aceite).
fallas(auto1,ruido_motor).

fallas(auto2,bateria_descargada).
fallas(auto2,luces_debiles).

fallas(auto3,vibracion_volante).
fallas(auto3,frenos_ruidosos).

kilometraje(auto1,250000).
kilometraje(auto2,80000).
kilometraje(auto3,120000).

%----ALERTAS CRÍTICAS----%
alerta_falla(humo_escape).
alerta_falla(fuga_combustible).
alerta_falla(temperatura_alta). 

tiene(V,F) :- fallas(V,F).

detectar_alerta(V,F) :-
    alerta_falla(F),
    tiene(V,F), !.  % Corte: si hay alerta, termina evaluación
	
%----VULNERABILIDAD----%
vulnerable(V) :-
    kilometraje(V, Km), Km >= 200000, !.
	
%----DIAGNÓSTICO----%
requisito(problema_bateria, bateria_descargada).
requisito(problema_bateria, luces_debiles).

requisito(problema_frenos, frenos_ruidosos).
requisito(problema_frenos, vibracion_volante).

requisito(problema_motor, ruido_motor).
requisito(problema_motor, perdida_aceite).

% Contraindicaciones (ej: no es problema de frenos si no hay vibración)
contraindica(problema_frenos, sin_vibracion).

% Cálculo de puntaje
puntaje(V, Dx, N) :-
    findall(S, (requisito(Dx,F), tiene(V,F)), SintomasPositivos),
    length(SintomasPositivos, Afectan),
    findall(C, (contraindica(Dx, C), tiene(V, C)), Contraindicaciones),
    length(Contraindicaciones, Restan),
    N is Afectan - Restan.

diagnostico(V, Dx, N) :- puntaje(V, Dx, N), N > 0.

%----PLAN DE REPARACIÓN----%
plan_para(urgente(_), remolque_taller).
plan_para(probable(problema_bateria), reemplazar_bateria).
plan_para(probable(problema_frenos), revisar_pastillas).
plan_para(probable(problema_motor), diagnostico_completo).

% Ajuste para vehículos vulnerables
ajustar_por_vulnerable(Plan, true, inspeccion_profunda(Plan)).
ajustar_por_vulnerable(Plan, false, Plan).

% --- Orquestador principal ---
evaluar_vehiculo(V, reporte{
    riesgo: Riesgo,
    diagnosticos: DxList,
    plan: PlanFinal,
    notas: Notas
}) :-
    ( detectar_alerta(V,F) 
        -> Riesgo = urgente,
           DxList = [],
           plan_para(urgente(S), Plan),
           ajustar_por_vulnerable(Plan, false, PlanFinal),
           Notas = [alerta(F), "¡Detener vehículo inmediatamente!"]
        ; Riesgo = no_urgente,
          (vulnerable(V) -> Vul = true ; Vul = false),
          findall(Dx, diagnostico(V, Dx, _), DxList),
          decidir_plan(DxList, Vul, PlanFinal, Notas)
    ).

decidir_plan([Dx], Vul, PlanFinal, [dx_principal(Dx)]) :-
    plan_para(probable(Dx), Plan),
    ajustar_por_vulnerable(Plan, Vul, PlanFinal).

decidir_plan([], _, sin_accion, ["Síntomas insuficientes"]).
