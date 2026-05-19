#!/usr/bin/env python3
"""
Convierte GTFS de Cochabamba a JSON para la app Flutter
Lee routes.txt, shapes.txt, trips.txt y genera rutas con polylines
"""
import csv
import json
import sys
from collections import defaultdict

def load_routes(routes_file):
    """Lee routes.txt y extrae info de rutas"""
    routes = {}
    with open(routes_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            route_id = row['route_id']
            routes[route_id] = {
                'id': int(route_id),
                'short_name': row['route_short_name'],
                'long_name': row['route_long_name'],
                'color': row.get('route_color', ''),
            }
    return routes

def load_trips(trips_file):
    """Lee trips.txt para mapear trip → shape"""
    trip_to_shape = {}
    with open(trips_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            trip_id = row['trip_id']
            shape_id = row['shape_id']
            route_id = row['route_id']
            if route_id not in trip_to_shape:
                trip_to_shape[route_id] = []
            trip_to_shape[route_id].append(shape_id)
    return trip_to_shape

def load_shapes(shapes_file):
    """Lee shapes.txt y agrupa coordenadas por shape_id"""
    shapes = defaultdict(list)
    with open(shapes_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            shape_id = row['shape_id']
            lat = float(row['shape_pt_lat'])
            lon = float(row['shape_pt_lon'])
            shapes[shape_id].append([lat, lon])
    return shapes

def main():
    gtfs_dir = 'assets/cochabamba_gtfs'
    
    print('Cargando GTFS de Cochabamba...')
    routes = load_routes(f'{gtfs_dir}/routes.txt')
    shapes = load_shapes(f'{gtfs_dir}/shapes.txt')
    trip_to_shape = load_trips(f'{gtfs_dir}/trips.txt')
    
    print(f'  - {len(routes)} rutas')
    print(f'  - {len(shapes)} shapes (polylines)')
    print(f'  - {len(trip_to_shape)} rutas con trips')
    
    # Construir rutas con sus segmentos
    final_routes = []
    for route_id, route_info in routes.items():
        shape_ids = trip_to_shape.get(route_id, [])
        
        # Tomar el primer shape de cada ruta (la mayoría tienen solo uno)
        segments = []
        for shape_id in set(shape_ids):
            if shape_id in shapes:
                segments.append(shapes[shape_id])
        
        if segments:
            final_routes.append({
                'id': route_info['id'],
                'name': f"{route_info['short_name']} - {route_info['long_name']}",
                'ref': route_info['short_name'],
                'color': f"#{route_info['color']}" if route_info['color'] else '#808080',
                'segments': segments
            })
    
    # Ordenar por ID
    final_routes.sort(key=lambda x: x['id'])
    
    # Guardar JSON
    output_file = 'assets/cochabamba_routes.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(final_routes, f, indent=2)
    
    print(f'\n✓ Guardado en {output_file}')
    print(f'  Rutas: {len(final_routes)}')
    print(f'  Tamaño: {((len(open(output_file).read())) / 1024):.1f} KB')
    
    # Mostrar sample
    print(f'\nSample (primeras 3 rutas):')
    for route in final_routes[:3]:
        num_points = sum(len(seg) for seg in route['segments'])
        print(f"  - {route['name']} ({num_points} puntos)")

if __name__ == '__main__':
    main()
